require 'gtk4'

class TextUndoDemo
  INTRO = 'The GtkTextView supports undo and redo through the use of a ' \
          'GtkTextBuffer. You can enable or disable undo support using ' \
          "gtk_text_buffer_set_enable_undo().\n" \
          "Type to add more text.\n" \
          'Use Control+z to undo and Control+Shift+z or Control+y to ' \
          'redo previously undone operations.'.freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Undo and Redo'
          win.set_default_size(330, 330)
          win.resizable = false
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = text_view }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.text_undo', :default_flags)
  def window = @window ||= Gtk::Window.new

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:automatic, :automatic) }
  end

  def text_view
    @text_view ||= Gtk::TextView.new.tap do |tv|
      tv.wrap_mode = :word
      tv.pixels_below_lines = 10
      tv.left_margin = 20
      tv.right_margin = 20
      tv.top_margin = 20
      tv.bottom_margin = 20

      tv.buffer.tap do |buffer|
        buffer.enable_undo = true
        buffer.begin_irreversible_action
        buffer.insert(buffer.start_iter, INTRO)
        buffer.end_irreversible_action
      end
    end
  end
end

TextUndoDemo.new.build.run
