require 'gtk4'

class InfoBarsDemo
  # message type, toggle label, whether the bar carries an OK button
  BARS = [
    [:info, 'Message', false],
    [:warning, 'Warning', false],
    [:question, 'Question', true],
    [:error, 'Error', false],
    [:other, 'Other', false]
  ].freeze

  BIND_FLAGS = GLib::BindingFlags::BIDIRECTIONAL | GLib::BindingFlags::SYNC_CREATE

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Info Bars'
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          bars.each { |bar| box.append(bar) }
          box.append(frame)

          frame.tap { |f| f.child = actions_box }

          actions_box.tap do |actions|
            toggles.each { |toggle| actions.append(toggle) }
          end

          bars.each_with_index do |bar, i|
            bar.bind_property('revealed', toggles[i], 'active', BIND_FLAGS)
          end

          question_bar.tap do |bar|
            bar.default_response = Gtk::ResponseType::OK
            bar.signal_connect('response') { |_, response| on_response(bar, response) }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.info_bars', :default_flags)
  def window = @window ||= Gtk::Window.new
  def question_bar = @question_bar ||= bars[2]

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
      box.margin_start = 8
      box.margin_end = 8
      box.margin_top = 8
      box.margin_bottom = 8
    end
  end

  def frame
    @frame ||= Gtk::Frame.new('An example of different info bars').tap do |f|
      f.margin_top = 8
      f.margin_bottom = 8
    end
  end

  def actions_box
    @actions_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.add_css_class('linked')
      box.halign = :center
      box.margin_start = 8
      box.margin_end = 8
      box.margin_top = 8
      box.margin_bottom = 8
    end
  end

  def bars = @bars ||= BARS.map { |type, _, with_ok| info_bar(type, with_ok) }

  def toggles
    @toggles ||= BARS.map { |_, label, _| Gtk::ToggleButton.new(label: label) }
  end

  private

  def info_bar(type, with_ok)
    Gtk::InfoBar.new.tap do |bar|
      bar.message_type = type
      bar.add_child(Gtk::Label.new("This is an info bar with message type GTK_MESSAGE_#{type.to_s.upcase}").tap do |label|
        label.wrap = true
        label.xalign = 0
      end)

      if with_ok
        bar.add_button('_OK', Gtk::ResponseType::OK)
        bar.show_close_button = true
      end
    end
  end

  def on_response(bar, response)
    Gtk::ResponseType::CLOSE.to_i.then do |close|
      if response.to_i == close
        bar.revealed = false
      else
        Gtk::AlertDialog.new.tap do |dialog|
          dialog.message = 'You clicked a button on an info bar'
          dialog.detail = "Your response has been #{response.to_i}"
          dialog.show(window)
        end
      end
    end
  end
end

InfoBarsDemo.new.build.run
