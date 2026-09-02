require 'gtk4'
require_relative 'nuclear'

class SimplePaintableDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Nuclear Icon'
          win.set_default_size(300, 200)
          win.child = image
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.paintable', :default_flags)
  def window = @window ||= Gtk::Window.new

  def image
    @image ||= Gtk::Image.new(paintable: NuclearIcon.new).tap { |i| i.pixel_size = 256 }
  end
end

SimplePaintableDemo.new.build.run
