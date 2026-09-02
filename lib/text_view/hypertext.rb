require 'gtk4'

class HypertextDemo
  # Tags do not have to change how text looks: these ones carry the page a
  # piece of text links to, and the view acts on them on click and on Enter.
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Hypertext'
          win.set_default_size(330, 330)
          win.resizable = false
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = text_view }

        text_view.tap do |view|
          view.buffer.enable_undo = true
          view.add_controller(key_controller)
          view.add_controller(click_gesture)
          view.add_controller(motion_controller)
        end

        key_controller.tap do |controller|
          controller.signal_connect('key-pressed') do |_, keyval, _, _|
            follow_link_at_cursor if [Gdk::Keyval::KEY_Return, Gdk::Keyval::KEY_KP_Enter].include?(keyval)
            false
          end
        end

        click_gesture.tap do |gesture|
          gesture.signal_connect('released') { |_, _, x, y| follow_link_at(gesture, x, y) }
        end

        motion_controller.tap do |controller|
          controller.signal_connect('motion') { |_, x, y| update_cursor(x, y) }
        end

        show_page(1)

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.hypertext', :default_flags)
  def window = @window ||= Gtk::Window.new
  def key_controller = @key_controller ||= Gtk::EventControllerKey.new
  def click_gesture = @click_gesture ||= Gtk::GestureClick.new
  def motion_controller = @motion_controller ||= Gtk::EventControllerMotion.new
  def link_pages = @link_pages ||= {}

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:never, :automatic) }
  end

  def text_view
    @text_view ||= Gtk::TextView.new.tap do |view|
      view.wrap_mode = :word
      view.top_margin = 20
      view.bottom_margin = 20
      view.left_margin = 20
      view.right_margin = 20
      view.pixels_below_lines = 10
    end
  end

  private

  def buffer = text_view.buffer

  def show_page(page)
    buffer.text = ''
    link_pages.clear

    buffer.begin_irreversible_action

    case page
    when 1 then build_index_page
    when 2 then build_entry_page('tag', 'tag', TAG_DEFINITION)
    else build_entry_page('hypertext', 'ˈhaɪ pərˌtɛkst', HYPERTEXT_DEFINITION)
    end

    buffer.end_irreversible_action
  end

  TAG_DEFINITION = "\nAn attribute that can be applied to some range of text. For example, " \
                   "a tag might be called “bold” and make the text inside the tag bold.\n" \
                   'However, the tag concept is more general than that; ' \
                   "tags don't have to affect appearance. They can instead affect the " \
                   "behavior of mouse and key presses, “lock” a range of text so the " \
                   "user can't edit it, or countless other things.\n".freeze

  HYPERTEXT_DEFINITION = "\nMachine-readable text that is not sequential but is organized " \
                         "so that related items of information are connected.\n".freeze

  def build_index_page
    end_iter.then do |iter|
      buffer.insert(iter, 'Some text to show that simple ')
      insert_link(iter, 'hypertext', 3)
      buffer.insert(iter, ' can easily be realized with ')
      insert_link(iter, 'tags', 2)
      buffer.insert(iter, ".\n")
      buffer.insert(iter, 'Of course you can also embed Emoji 😋, ')
      buffer.insert(iter, 'icons ')
      buffer.insert(iter, conceal_icon)
      buffer.insert(iter, ', or even widgets ')
      insert_widget(iter, level_bar, nil)
      buffer.insert(iter, ' and labels with ')
      insert_widget(iter, Gtk::Label.new('ghost'), '👻')
      buffer.insert(iter, ' text.')
    end
  end

  # A dictionary-style entry: headword, pronunciation, a speaker button and
  # the definition, ending in a link back to the index.
  def build_entry_page(word, pronunciation, definition)
    end_iter.then do |iter|
      insert_unbreakable(iter) { buffer.insert(iter, word, tags: [bold_tag]) }
      insert_unbreakable(iter) { buffer.insert(iter, pronunciation, tags: [mono_tag]) }
      insert_widget(iter, speaker_icon(word), nil)
      buffer.insert(iter, definition)
      insert_link(iter, 'Go back', 1)
    end
  end

  # Keeps the headword and its trailing " /" on one line.
  def insert_unbreakable(iter)
    buffer.create_mark(nil, iter, true).tap do |mark|
      yield
      buffer.insert(iter, ' /')
      buffer.apply_tag(nobreaks_tag, buffer.get_iter_at(mark: mark), iter)
      buffer.insert(iter, ' ')
      buffer.delete_mark(mark)
    end
  end

  def insert_link(iter, text, page)
    buffer.create_tag(nil, 'foreground' => 'blue', 'underline' => :single).tap do |tag|
      link_pages[tag] = page
      buffer.insert(iter, text, tags: [tag])
    end
  end

  # Gtk::TextBuffer#insert and #insert_child_anchor both dispatch to a raw
  # method the bindings do not define, so the raw inserter is used directly.
  def insert_widget(iter, child, replacement)
    (replacement ? Gtk::TextChildAnchor.new(replacement) : Gtk::TextChildAnchor.new).tap do |anchor|
      buffer.insert_child_anchor_raw(iter, anchor)
      text_view.add_child_at_anchor(child, anchor)
    end
  end

  def level_bar
    Gtk::LevelBar.new(0, 100).tap do |bar|
      bar.value = 50
      bar.set_size_request(100, -1)
    end
  end

  # Quick-and-dirty text to speech; silent unless espeak-ng is installed.
  def speaker_icon(word)
    Gtk::Image.new(icon_name: 'audio-volume-high-symbolic').tap do |image|
      image.set_cursor_from_name('pointer')
      image.add_controller(Gtk::GestureClick.new.tap do |gesture|
        gesture.signal_connect('pressed') { spawn_speech(word) }
      end)
    end
  end

  def spawn_speech(word)
    GLib::Spawn.async(nil, ['espeak-ng', word], nil, GLib::Spawn::SEARCH_PATH)
  rescue GLib::Error
    nil
  end

  def conceal_icon
    Gtk::IconTheme.get_for_display(window.display)
                  .lookup_icon('view-conceal-symbolic', 16, direction: :ltr)
  end

  def bold_tag = @bold_tag ||= buffer.create_tag(nil, 'weight' => :bold, 'scale' => 1.2)
  def mono_tag = @mono_tag ||= buffer.create_tag(nil, 'family' => 'monospace')
  def nobreaks_tag = @nobreaks_tag ||= buffer.create_tag(nil, 'allow-breaks' => false)

  def end_iter = buffer.get_iter_at(offset: 0)

  def follow_link_at_cursor
    follow_link(buffer.get_iter_at(mark: buffer.get_insert))
  end

  def follow_link_at(gesture, x, y)
    if gesture.button <= 1 && buffer.selection_bounds.first == buffer.selection_bounds[1]
      text_view.window_to_buffer_coords(:widget, x, y).then do |bx, by|
        text_view.get_iter_at_location(bx, by).then { |found, iter| follow_link(iter) if found }
      end
    end
  end

  def follow_link(iter)
    iter.tags.each do |tag|
      link_pages[tag].then { |page| break show_page(page) if page }
    end
  end

  # A hand cursor over links, an I-beam everywhere else.
  def update_cursor(x, y)
    text_view.window_to_buffer_coords(:widget, x, y).then do |bx, by|
      text_view.get_iter_at_location(bx, by).then do |found, iter|
        (found && iter.tags.any? { |tag| link_pages.key?(tag) }).then do |hovering|
          text_view.set_cursor_from_name(hovering ? 'pointer' : 'text') if hovering != @hovering
          @hovering = hovering
        end
      end
    end
  end
end

HypertextDemo.new.build.run
