require 'gtk4'

class LinksDemo
  MARKUP = 'Some <a href="http://en.wikipedia.org/wiki/Text" title="plain text">text</a> ' \
           'may be marked up as hyperlinks, which can be clicked or activated via ' \
           '<a href="keynav">keynav</a> and they work fine with other markup, like when ' \
           'linking to <a href="http://www.flathub.org/"><b>' \
           '<span letter_spacing="1024" underline="none" color="pink" background="darkslategray">Flathub</span>' \
           '</b></a>.'.freeze

  KEYNAV_DETAIL = 'The term ‘keynav’ is a shorthand for keyboard navigation and refers ' \
                  'to the process of using a program (exclusively) via keyboard input.'.freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Links'
          win.resizable = false
          win.child = label
        end

        label.tap do |l|
          l.signal_connect('activate-link') { |_, uri| show_keynav_dialog if uri == 'keynav' }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.links', :default_flags)
  def window = @window ||= Gtk::Window.new

  def label
    @label ||= Gtk::Label.new(MARKUP).tap do |l|
      l.use_markup = true
      l.max_width_chars = 40
      l.wrap = true
      l.wrap_mode = :word
      l.margin_start = 20
      l.margin_end = 20
      l.margin_top = 20
      l.margin_bottom = 20
    end
  end

  private

  def show_keynav_dialog
    Gtk::AlertDialog.new.tap do |dialog|
      dialog.message = 'Keyboard navigation'
      dialog.detail = KEYNAV_DETAIL
      dialog.show(window)
    end
  end
end

LinksDemo.new.build.run
