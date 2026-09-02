require 'gtk4'

class TabsDemo
  TEXT = "one\t2.0\tthree\nfour\t5.555\tsix\nseven\t88.88\tnine".freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Tabs'
          win.set_default_size(330, 130)
          win.resizable = false
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = text_view }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.tabs', :default_flags)
  def window = @window ||= Gtk::Window.new

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap { |sw| sw.set_policy(:never, :automatic) }
  end

  def text_view
    @text_view ||= Gtk::TextView.new.tap do |tv|
      tv.wrap_mode = :word
      tv.top_margin = 20
      tv.bottom_margin = 20
      tv.left_margin = 20
      tv.right_margin = 20
      tv.tabs = tab_array
      tv.buffer.text = TEXT
    end
  end

  # Left aligned, decimal aligned on '.', then right aligned.
  def tab_array
    @tab_array ||= Pango::TabArray.new(3, true).tap do |tabs|
      tabs.set_tab(0, :left, 0)
      tabs.set_tab(1, :decimal, 150)
      tabs.set_decimal_point(1, '.'.ord)
      tabs.set_tab(2, :right, 290)
    end
  end
end

TabsDemo.new.build.run
