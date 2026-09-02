require 'gtk4'
require_relative 'css_editor'

class MultipleBackgroundsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Multiple Backgrounds'
          win.set_default_size(400, 300)
          win.add_css_class('demo')
          win.child = overlay
        end

        overlay.tap do |o|
          o.child = canvas
          o.add_overlay(bricks_button)
          o.add_overlay(paned)

          paned.tap do |p|
            p.start_child = filler
            p.end_child = editor.build
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.multiple_backgrounds', :default_flags)
  def window = @window ||= Gtk::Window.new
  def overlay = @overlay ||= Gtk::Overlay.new
  def paned = @paned ||= Gtk::Paned.new(:vertical)
  def editor = @editor ||= CssEditor.new('css_multiplebgs.css')

  # No draw func: the demo is only interested in what CSS paints for us.
  def canvas = @canvas ||= Gtk::DrawingArea.new.tap { |da| da.name = 'canvas' }

  # The paned needs a start child so that its handle is draggable.
  def filler = @filler ||= Gtk::Box.new(:vertical, 0)

  def bricks_button
    @bricks_button ||= Gtk::Button.new.tap do |btn|
      btn.name = 'bricks-button'
      btn.halign = :center
      btn.valign = :center
      btn.set_size_request(250, 84)
    end
  end
end

MultipleBackgroundsDemo.new.build.run
