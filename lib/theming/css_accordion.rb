require 'gtk4'

class CssAccordionDemo
  ASSETS = File.expand_path('../../demos/gtk-demo', __dir__).freeze
  LABELS = ['This', 'Is', 'A', 'CSS', 'Accordion', ':-)'].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'CSS Accordion'
          win.set_default_size(600, 300)
          win.child = styled_frame
        end

        styled_frame.tap do |frame|
          frame.child = button_box

          button_box.tap do |box|
            buttons.each { |button| box.append(button) }
          end
        end

        Gtk::StyleContext.add_provider_for_display(Gdk::Display.default, provider, PRIORITY)

        window.present
      end
    end
  end

  PRIORITY = Gtk::StyleProvider::PRIORITY_APPLICATION

  def app = @app ||= Gtk::Application.new('org.example.css_accordion', :default_flags)
  def window = @window ||= Gtk::Window.new
  def buttons = @buttons ||= LABELS.map { |label| Gtk::Button.new(label: label) }

  def styled_frame = @styled_frame ||= Gtk::Frame.new.tap { |f| f.add_css_class('accordion') }

  def button_box
    @button_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.halign = :center
      box.valign = :center
    end
  end

  def provider
    @provider ||= Gtk::CssProvider.new.tap do |p|
      p.load(path: File.join(ASSETS, 'css_accordion.css'))
    end
  end
end

CssAccordionDemo.new.build.run
