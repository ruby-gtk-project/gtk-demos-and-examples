require 'gtk4'
require_relative 'css_editor'

class CssBasicsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'CSS Basics'
          win.set_default_size(400, 300)
          win.add_css_class('demo')
          win.child = editor.build
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.css_basics', :default_flags)
  def window = @window ||= Gtk::Window.new
  def editor = @editor ||= CssEditor.new('css_basics.css')
end

CssBasicsDemo.new.build.run
