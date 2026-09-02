require 'gtk4'
require_relative 'css_editor'

class AnimatedBackgroundsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Animated Backgrounds'
          win.set_default_size(400, 300)
          win.add_css_class('demo')
          win.child = paned
        end

        paned.tap do |p|
          p.start_child = filler
          p.end_child = editor.build
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.animated_backgrounds', :default_flags)
  def window = @window ||= Gtk::Window.new
  def paned = @paned ||= Gtk::Paned.new(:vertical)
  def editor = @editor ||= CssEditor.new('css_pixbufs.css')

  # The paned needs a start child so that its handle is draggable.
  def filler = @filler ||= Gtk::Box.new(:vertical, 0)
end

AnimatedBackgroundsDemo.new.build.run
