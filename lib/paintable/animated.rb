require 'gtk4'
require_relative 'nuclear'

class AnimatedPaintableDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Nuclear Animation'
          win.set_default_size(300, 200)
          win.child = image
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.paintable_animated', :default_flags)
  def window = @window ||= Gtk::Window.new

  def image
    @image ||= Gtk::Image.new(paintable: NuclearAnimation.new(true)).tap { |i| i.pixel_size = 256 }
  end
end

AnimatedPaintableDemo.new.build.run
