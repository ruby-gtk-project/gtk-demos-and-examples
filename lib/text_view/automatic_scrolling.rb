require 'gtk4'

# A text view that keeps appending lines and scrolling to follow them.
#
# The two modes differ in the gravity of the mark they scroll to: a
# right-gravity mark sits at the end of the buffer and drags the view
# horizontally too, while a left-gravity mark stays where it was put at the
# start of the line, so only vertical scrolling happens.
class ScrollingTextView
  END_INTERVAL = 50
  BOTTOM_INTERVAL = 100

  def initialize(to_end:)
    @to_end = to_end
    @count = 0
  end

  def build
    @build ||= scrolled_window.tap do |sw|
      sw.child = text_view
      buffer.create_mark(mark_name, buffer.end_iter, !@to_end)
      start_scrolling
    end
  end

  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new
  def text_view = @text_view ||= Gtk::TextView.new
  def buffer = text_view.buffer
  def mark_name = @to_end ? 'end' : 'scroll'

  private

  def start_scrolling
    GLib::Timeout.add(@to_end ? END_INTERVAL : BOTTOM_INTERVAL) do
      @to_end ? scroll_to_end : scroll_to_bottom
      GLib::Source::CONTINUE
    end
  end

  def scroll_to_end
    buffer.get_iter_at(mark: buffer.get_mark('end')).tap do |iter|
      append(iter, "Scroll to end scroll to end scroll to end scroll to end #{advance(150)}")
    end

    text_view.scroll_mark_onscreen(buffer.get_mark('end'))
  end

  def scroll_to_bottom
    buffer.end_iter.tap do |iter|
      append(iter, "Scroll to bottom scroll to bottom scroll to bottom scroll to bottom #{advance(40)}")
      iter.line_offset = 0
      buffer.move_mark(buffer.get_mark('scroll'), iter)
    end

    text_view.scroll_mark_onscreen(buffer.get_mark('scroll'))
  end

  # Indents one more space on every line, then starts over, like a typewriter
  # running off the right-hand side of the page.
  def advance(limit)
    @count += 1
    @count = 0 if @count > limit
    @count
  end

  def append(iter, text)
    buffer.insert(iter, "\n")
    buffer.insert(iter, ' ' * @count)
    buffer.insert(iter, text)
  end
end

class AutomaticScrollingDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Automatic Scrolling'
          win.set_default_size(600, 400)
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(end_view.build)
          box.append(bottom_view.build)
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.text_scroll', :default_flags)
  def window = @window ||= Gtk::Window.new
  def end_view = @end_view ||= ScrollingTextView.new(to_end: true)
  def bottom_view = @bottom_view ||= ScrollingTextView.new(to_end: false)

  def content_box
    @content_box ||= Gtk::Box.new(:horizontal, 6).tap { |box| box.homogeneous = true }
  end
end

AutomaticScrollingDemo.new.build.run
