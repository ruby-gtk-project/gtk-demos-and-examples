require 'gtk4'

class SpinnerDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Spinner'
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(sensitive_box)
          box.append(insensitive_box)
          box.append(play_button)
          box.append(stop_button)

          sensitive_box.tap do |row|
            row.append(sensitive_spinner)
            row.append(sensitive_entry)
          end

          insensitive_box.tap do |row|
            row.append(insensitive_spinner)
            row.append(insensitive_entry)
          end

          play_button.tap do |btn|
            btn.signal_connect('clicked') { start_spinners }
          end

          stop_button.tap do |btn|
            btn.signal_connect('clicked') { stop_spinners }
          end
        end

        start_spinners

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.spinner', :default_flags)
  def window = @window ||= Gtk::Window.new
  def sensitive_box = @sensitive_box ||= Gtk::Box.new(:horizontal, 5)
  def sensitive_spinner = @sensitive_spinner ||= Gtk::Spinner.new
  def sensitive_entry = @sensitive_entry ||= Gtk::Entry.new
  def insensitive_spinner = @insensitive_spinner ||= Gtk::Spinner.new
  def insensitive_entry = @insensitive_entry ||= Gtk::Entry.new
  def play_button = @play_button ||= Gtk::Button.new(label: 'Play')
  def stop_button = @stop_button ||= Gtk::Button.new(label: 'Stop')

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 10).tap do |box|
      box.margin_start = 5
      box.margin_end = 5
      box.margin_top = 5
      box.margin_bottom = 5
    end
  end

  def insensitive_box
    @insensitive_box ||= Gtk::Box.new(:horizontal, 5).tap { |box| box.sensitive = false }
  end

  private

  def start_spinners
    sensitive_spinner.start
    insensitive_spinner.start
  end

  def stop_spinners
    sensitive_spinner.stop
    insensitive_spinner.stop
  end
end

SpinnerDemo.new.build.run
