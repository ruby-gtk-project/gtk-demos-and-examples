require 'gtk4'

class PasswordEntryDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Choose a Password'
          win.resizable = false
          win.deletable = false
          win.titlebar = header_bar
          win.child = content_box
          win.default_widget = done_button
        end

        header_bar.tap { |header| header.pack_end(done_button) }

        content_box.tap do |box|
          box.append(password_entry)
          box.append(confirm_entry)

          password_entry.tap { |e| e.signal_connect('notify::text') { update_done_button } }
          confirm_entry.tap { |e| e.signal_connect('notify::text') { update_done_button } }
        end

        done_button.tap { |btn| btn.signal_connect('clicked') { window.destroy } }

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.password_entry', :default_flags)
  def window = @window ||= Gtk::Window.new
  def password_entry = @password_entry ||= secret_entry('Password')
  def confirm_entry = @confirm_entry ||= secret_entry('Confirm')

  def header_bar
    @header_bar ||= Gtk::HeaderBar.new.tap { |header| header.show_title_buttons = false }
  end

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 6).tap do |box|
      box.margin_start = 18
      box.margin_end = 18
      box.margin_top = 18
      box.margin_bottom = 18
    end
  end

  def done_button
    @done_button ||= Gtk::Button.new.tap do |btn|
      btn.label = '_Done'
      btn.use_underline = true
      btn.add_css_class('suggested-action')
      btn.sensitive = false
    end
  end

  private

  def secret_entry(placeholder)
    Gtk::PasswordEntry.new.tap do |entry|
      entry.show_peek_icon = true
      entry.placeholder_text = placeholder
      entry.activates_default = true
    end
  end

  def update_done_button
    done_button.sensitive = !password_entry.text.empty? && password_entry.text == confirm_entry.text
  end
end

PasswordEntryDemo.new.build.run
