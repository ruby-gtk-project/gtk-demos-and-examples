require 'gtk4'
require_relative 'css_editor'

class ShadowsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Shadows'
          win.set_default_size(400, 300)
          win.add_css_class('demo')
          win.child = paned
        end

        paned.tap do |p|
          p.start_child = toolbar
          p.resize_start_child = false
          p.end_child = editor.build

          toolbar.tap do |bar|
            bar.append(next_button)
            bar.append(previous_button)
            bar.append(hello_button)
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.shadows', :default_flags)
  def window = @window ||= Gtk::Window.new
  def paned = @paned ||= Gtk::Paned.new(:vertical)
  def editor = @editor ||= CssEditor.new('css_shadows.css')
  def next_button = @next_button ||= Gtk::Button.new(icon_name: 'go-next')
  def previous_button = @previous_button ||= Gtk::Button.new(icon_name: 'go-previous')
  def hello_button = @hello_button ||= Gtk::Button.new(label: 'Hello World')

  def toolbar
    @toolbar ||= Gtk::Box.new(:horizontal, 6).tap { |bar| bar.valign = :center }
  end
end

ShadowsDemo.new.build.run
