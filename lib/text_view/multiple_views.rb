require 'gtk4'
require_relative '../paintable/nuclear'

class MultipleViewsDemo
  XX_SMALL = 1 / 1.2**3
  X_LARGE = 1.2

  # Tags get their priority from the order they are added to the tag table:
  # a later tag wins over an earlier one that sets the same property.
  TAGS = {
    'heading' => { 'weight' => :bold, 'size' => 15 * Pango::SCALE },
    'italic' => { 'style' => :italic },
    'bold' => { 'weight' => :bold },
    'big' => { 'size' => 20 * Pango::SCALE },
    'xx-small' => { 'scale' => XX_SMALL },
    'x-large' => { 'scale' => X_LARGE },
    'monospace' => { 'family' => 'monospace' },
    'blue_foreground' => { 'foreground' => 'blue' },
    'red_background' => { 'background' => 'red' },
    'big_gap_before_line' => { 'pixels_above_lines' => 30 },
    'big_gap_after_line' => { 'pixels_below_lines' => 30 },
    'double_spaced_line' => { 'pixels_inside_wrap' => 10 },
    'not_editable' => { 'editable' => false },
    'word_wrap' => { 'wrap_mode' => :word },
    'char_wrap' => { 'wrap_mode' => :char },
    'no_wrap' => { 'wrap_mode' => :none },
    'center' => { 'justification' => :center },
    'right_justify' => { 'justification' => :right },
    'wide_margins' => { 'left_margin' => 50, 'right_margin' => 50 },
    'strikethrough' => { 'strikethrough' => true },
    'underline' => { 'underline' => :single },
    'double_underline' => { 'underline' => :double },
    'superscript' => { 'rise' => 10 * Pango::SCALE, 'size' => 8 * Pango::SCALE },
    'subscript' => { 'rise' => -10 * Pango::SCALE, 'size' => 8 * Pango::SCALE },
    'rtl_quote' => { 'wrap_mode' => :word, 'direction' => :rtl, 'indent' => 30,
                     'left_margin' => 20, 'right_margin' => 20 }
  }.freeze

  ARABIC_QUOTE = 'وقد بدأ ثلاث من أكثر المؤسسات تقدما في شبكة اكسيون برامجها ' \
                 'كمنظمات لا تسعى للربح، ثم تحولت في السنوات الخمس الماضية إلى ' \
                 'مؤسسات مالية منظمة، وباتت جزءا من النظام المالي في بلدانها، ' \
                 'ولكنها تتخصص في خدمة قطاع المشروعات الصغيرة. وأحد أكثر هذه ' \
                 'المؤسسات نجاحا هو »بانكوسول« في بوليفيا.'.freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Multiple Views'
          win.set_default_size(450, 450)
          win.child = paned
        end

        paned.tap do |p|
          p.start_child = top_scroller
          p.resize_start_child = false
          p.shrink_start_child = true
          p.end_child = bottom_scroller
          p.resize_end_child = true
          p.shrink_end_child = true

          top_scroller.tap { |sw| sw.child = top_view }
          bottom_scroller.tap { |sw| sw.child = bottom_view }
        end

        create_tags
        insert_text
        attach_widgets(top_view)
        attach_widgets(bottom_view)

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.textview', :default_flags)
  def window = @window ||= Gtk::Window.new
  def paned = @paned ||= Gtk::Paned.new(:vertical)
  def top_scroller = @top_scroller ||= scroller
  def bottom_scroller = @bottom_scroller ||= scroller
  def top_view = @top_view ||= Gtk::TextView.new

  # Both views share one buffer, which is the whole point of the demo.
  def bottom_view = @bottom_view ||= Gtk::TextView.new(buffer)
  def buffer = top_view.buffer
  def anchors = @anchors ||= []

  private

  def scroller
    Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:automatic, :automatic) }
  end

  def create_tags
    TAGS.each { |name, properties| buffer.create_tag(name, properties) }
  end

  def insert_text
    buffer.begin_irreversible_action

    buffer.get_iter_at(offset: 0).then do |iter|
      insert_intro(iter)
      insert_font_styles(iter)
      insert_colors(iter)
      insert_decorations(iter)
      insert_images(iter)
      insert_spacing(iter)
      insert_editability(iter)
      insert_wrapping(iter)
      insert_justification(iter)
      insert_internationalization(iter)
      insert_widget_anchors(iter)
    end

    buffer.apply_tag_by_name('word_wrap', buffer.start_iter, buffer.end_iter)
    buffer.end_irreversible_action
  end

  def plain(iter, text) = buffer.insert(iter, text)

  def tagged(iter, text, *tag_names)
    buffer.insert(iter, text, tags: tag_names.map { |name| buffer.tag_table.lookup(name) })
  end

  def insert_intro(iter)
    plain(iter, "The text widget can display text with all kinds of nifty attributes. " \
                "It also supports multiple views of the same buffer; this demo is " \
                "showing the same buffer in two places.\n\n")
  end

  def insert_font_styles(iter)
    tagged(iter, 'Font styles. ', 'heading')
    plain(iter, 'For example, you can have ')
    tagged(iter, 'italic', 'italic')
    plain(iter, ', ')
    tagged(iter, 'bold', 'bold')
    plain(iter, ', or ')
    tagged(iter, 'monospace (typewriter)', 'monospace')
    plain(iter, ', or ')
    tagged(iter, 'big', 'big')
    plain(iter, ' text. ')
    plain(iter, "It's best not to hardcode specific text sizes; you can use relative " \
                'sizes as with CSS, such as ')
    tagged(iter, 'xx-small', 'xx-small')
    plain(iter, ' or ')
    tagged(iter, 'x-large', 'x-large')
    plain(iter, " to ensure that your program properly adapts if the user changes the " \
                "default font size.\n\n")
  end

  def insert_colors(iter)
    tagged(iter, 'Colors. ', 'heading')
    plain(iter, 'Colors such as ')
    tagged(iter, 'a blue foreground', 'blue_foreground')
    plain(iter, ' or ')
    tagged(iter, 'a red background', 'red_background')
    plain(iter, ' or even ')
    tagged(iter, 'a blue foreground on red background', 'blue_foreground', 'red_background')
    plain(iter, " (select that to read it) can be used.\n\n")
  end

  def insert_decorations(iter)
    tagged(iter, 'Underline, strikethrough, and rise. ', 'heading')
    tagged(iter, 'Strikethrough', 'strikethrough')
    plain(iter, ', ')
    tagged(iter, 'underline', 'underline')
    plain(iter, ', ')
    tagged(iter, 'double underline', 'double_underline')
    plain(iter, ', ')
    tagged(iter, 'superscript', 'superscript')
    plain(iter, ', and ')
    tagged(iter, 'subscript', 'subscript')
    plain(iter, " are all supported.\n\n")
  end

  def insert_images(iter)
    tagged(iter, 'Images. ', 'heading')
    plain(iter, 'The buffer can have images in it: ')
    buffer.insert(iter, disk_icon)
    buffer.insert(iter, NuclearAnimation.new(true))
    plain(iter, " for example.\n\n")
  end

  def insert_spacing(iter)
    tagged(iter, 'Spacing. ', 'heading')
    plain(iter, "You can adjust the amount of space before each line.\n")
    tagged(iter, "This line has a whole lot of space before it.\n",
           'big_gap_before_line', 'wide_margins')
    tagged(iter, 'You can also adjust the amount of space after each line; ' \
                 "this line has a whole lot of space after it.\n",
           'big_gap_after_line', 'wide_margins')
    tagged(iter, 'You can also adjust the amount of space between wrapped lines; ' \
                 'this line has extra space between each wrapped line in the same ' \
                 'paragraph. To show off wrapping, some filler text: the quick ' \
                 'brown fox jumped over the lazy dog. Blah blah blah blah blah ' \
                 "blah blah blah blah.\n",
           'double_spaced_line', 'wide_margins')
    plain(iter, "Also note that those lines have extra-wide margins.\n\n")
  end

  def insert_editability(iter)
    tagged(iter, 'Editability. ', 'heading')
    tagged(iter, "This line is 'locked down' and can't be edited by the user - just " \
                 "try it! You can't delete this line.\n\n",
           'not_editable')
  end

  def insert_wrapping(iter)
    tagged(iter, 'Wrapping. ', 'heading')
    plain(iter, 'This line (and most of the others in this buffer) is word-wrapped, ' \
                'using the proper Unicode algorithm. Word wrap should work in all ' \
                "scripts and languages that GTK supports. Let's make this a long " \
                'paragraph to demonstrate: blah blah blah blah blah blah blah blah ' \
                "blah blah blah blah blah blah blah blah blah blah blah\n\n")
    tagged(iter, 'This line has character-based wrapping, and can wrap between any two ' \
                 "character glyphs. Let's make this a long paragraph to demonstrate: " \
                 'blah blah blah blah blah blah blah blah blah blah blah blah blah blah ' \
                 "blah blah blah blah blah\n\n",
           'char_wrap')
    tagged(iter, 'This line has all wrapping turned off, so it makes the horizontal ' \
                 "scrollbar appear.\n\n\n",
           'no_wrap')
  end

  def insert_justification(iter)
    tagged(iter, 'Justification. ', 'heading')
    tagged(iter, "\nThis line has center justification.\n", 'center')
    tagged(iter, "This line has right justification.\n", 'right_justify')
    tagged(iter, "\nThis line has big wide margins. Text text text text text text text " \
                 'text text text text text text text text text text text text text text ' \
                 'text text text text text text text text text text text text text text ' \
                 "text.\n",
           'wide_margins')
  end

  def insert_internationalization(iter)
    tagged(iter, 'Internationalization. ', 'heading')
    plain(iter, "You can put all sorts of Unicode text in the buffer.\n\nGerman " \
                "(Deutsch Süd) Grüß Gott\nGreek (Ελληνικά) Γειά σας\nHebrew      שלום\n" \
                "Japanese (日本語)\n\nThe widget properly handles " \
                'bidirectional text, word wrapping, DOS/UNIX/Unicode paragraph separators, ' \
                'grapheme boundaries, and so on using the Pango internationalization ' \
                "framework.\n")
    plain(iter, "Here's a word-wrapped quote in a right-to-left language:\n")
    tagged(iter, "#{ARABIC_QUOTE}\n\n", 'rtl_quote')
  end

  # The anchors are created empty here; each view fills them with its own
  # widgets, because a widget can only live in one view at a time.
  def insert_widget_anchors(iter)
    plain(iter, "You can put widgets in the buffer: Here's a button: ")
    anchors << buffer.create_child_anchor(iter)
    plain(iter, ' and a menu: ')
    anchors << buffer.create_child_anchor(iter)
    plain(iter, ' and a scale: ')
    anchors << buffer.create_child_anchor(iter)
    plain(iter, ' finally a text entry: ')
    anchors << buffer.create_child_anchor(iter)
    plain(iter, ".\n")
    plain(iter, "\n\nThis demo doesn't demonstrate all the GtkTextBuffer features; " \
                'it leaves out, for example: invisible/hidden text, tab stops, ' \
                'application-drawn areas on the sides of the widget for displaying ' \
                'breakpoints and such...')
  end

  def attach_widgets(view)
    anchors.each_with_index do |anchor, index|
      view.add_child_at_anchor(anchor_widget(index), anchor)
    end
  end

  def anchor_widget(index)
    case index
    when 0 then easter_egg_button
    when 1 then Gtk::DropDown.new(['Option 1', 'Option 2', 'Option 3'])
    when 2 then Gtk::Scale.new(:horizontal, nil).tap { |s| s.set_range(0, 100); s.set_size_request(100, -1) }
    else Gtk::Entry.new.tap { |e| e.width_chars = 10 }
    end
  end

  def easter_egg_button
    Gtk::Button.new(label: 'Click Me').tap do |btn|
      btn.signal_connect('clicked') { EasterEgg.new(window).build.present }
    end
  end

  def disk_icon
    Gtk::IconTheme.get_for_display(window.display).lookup_icon('drive-harddisk', 32)
  end
end

# A window full of text views nested inside each other, all sharing one
# buffer. Please do not do this in real applications.
class EasterEgg
  MAX_DEPTH = 4

  def initialize(parent)
    @parent = parent
  end

  def build
    @build ||= window.tap do |win|
      win.transient_for = @parent
      win.modal = true
      win.set_default_size(300, 400)
      win.child = scrolled_window

      scrolled_window.tap { |sw| sw.child = view }

      buffer.get_iter_at(offset: 0).then do |iter|
        buffer.insert(iter, "This buffer is shared by a set of nested text views.\n Nested view:\n")
        buffer.create_child_anchor(iter).tap { |anchor| attach(0, view, anchor) }
        buffer.insert(iter, "\nDon't do this in real applications, please.\n")
      end
    end
  end

  def window = @window ||= Gtk::Window.new
  def buffer = @buffer ||= Gtk::TextBuffer.new
  def view = @view ||= Gtk::TextView.new(buffer)

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:automatic, :automatic) }
  end

  private

  def attach(depth, parent_view, anchor)
    if depth <= MAX_DEPTH
      Gtk::TextView.new(buffer).tap do |child|
        child.set_size_request(260 - (20 * depth), -1)
        parent_view.add_child_at_anchor(Gtk::Frame.new.tap { |f| f.child = child }, anchor)
        attach(depth + 1, child, anchor)
      end
    end
  end
end

MultipleViewsDemo.new.build.run
