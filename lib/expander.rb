require 'gtk4'

class ExpanderDemo
  DETAILS = "Finally, the full story with all details. And all the inside " \
            "information, including error codes, etc etc. Pages of information, " \
            "you might have to scroll down to read it all, or even resize the " \
            "window - it works !\n" \
            "A second paragraph will contain even more innuendo, just to make " \
            "you scroll down or resize the window.\n" \
            "Do it already!\n".freeze

  LOGO = File.expand_path('../demos/gtk-demo/gtk_logo_cursor.png', __dir__).freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Expander'
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(title_label)
          box.append(summary_label)
          box.append(expander)

          expander.tap do |exp|
            exp.child = scrolled_window
            exp.signal_connect('notify::expanded') { window.resizable = exp.expanded? }
          end

          scrolled_window.tap { |sw| sw.child = text_view }
        end

        append_logo

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.expander', :default_flags)
  def window = @window ||= Gtk::Window.new

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 10).tap do |box|
      box.margin_start = 10
      box.margin_end = 10
      box.margin_top = 10
      box.margin_bottom = 10
    end
  end

  def title_label
    @title_label ||= Gtk::Label.new('<big><b>Something went wrong</b></big>').tap do |l|
      l.use_markup = true
    end
  end

  def summary_label
    @summary_label ||= Gtk::Label.new('Here are some more details but not the full story').tap do |l|
      l.wrap = false
      l.vexpand = false
    end
  end

  def expander = @expander ||= Gtk::Expander.new('Details:').tap { |e| e.vexpand = true }

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.min_content_height = 100
      sw.has_frame = true
      sw.set_policy(:never, :automatic)
      sw.propagate_natural_height = true
      sw.vexpand = true
    end
  end

  def text_view
    @text_view ||= Gtk::TextView.new.tap do |tv|
      tv.left_margin = 10
      tv.right_margin = 10
      tv.top_margin = 10
      tv.bottom_margin = 10
      tv.editable = false
      tv.cursor_visible = false
      tv.wrap_mode = :word
      tv.pixels_above_lines = 2
      tv.pixels_below_lines = 2
      tv.buffer.text = DETAILS
    end
  end

  private

  def append_logo
    Gdk::Texture.new(Gio::File.new_for_path(LOGO)).then do |texture|
      text_view.buffer.tap do |buffer|
        buffer.insert(buffer.end_iter, texture)
        buffer.apply_tag(
          buffer.create_tag(nil, 'pixels-above-lines' => 200, 'justification' => :right),
          buffer.get_iter_at(offset: buffer.end_iter.offset - 1),
          buffer.end_iter
        )
      end
    end
  end
end

ExpanderDemo.new.build.run
