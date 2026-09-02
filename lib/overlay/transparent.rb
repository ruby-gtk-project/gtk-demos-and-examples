require 'gtk4'

class TransparentOverlayDemo
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze
  CSS_FILE = File.join(ASSETS, 'transparent.css').freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Transparency'
          win.set_default_size(450, 450)
          win.child = overlay
        end

        overlay.tap do |o|
          o.child = picture
          o.add_overlay(controls_box)

          controls_box.tap do |box|
            box.append(first_button)
            box.append(second_button)
          end
        end

        Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, PRIORITY)

        window.present
      end
    end
  end

  PRIORITY = Gtk::StyleProvider::PRIORITY_APPLICATION

  def app = @app ||= Gtk::Application.new('org.example.transparent', :default_flags)
  def window = @window ||= Gtk::Window.new
  def overlay = @overlay ||= Gtk::Overlay.new
  def first_button = @first_button ||= blur_button("Don't click this button!")
  def second_button = @second_button ||= blur_button('Maybe this one?')
  def provider = @provider ||= Gtk::CssProvider.new.tap { |p| p.load(path: CSS_FILE) }

  def picture
    @picture ||= Gtk::Picture.new(File.join(ASSETS, 'portland-rose.jpg')).tap do |p|
      p.content_fit = :cover
    end
  end

  def controls_box
    @controls_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.hexpand = true
      box.homogeneous = true
      box.add_css_class('floating-controls')
      box.halign = :fill
      box.valign = :end
    end
  end

  private

  def blur_button(label)
    Gtk::Button.new(label: label).tap { |btn| btn.add_css_class('blur-overlay') }
  end
end

TransparentOverlayDemo.new.build.run
