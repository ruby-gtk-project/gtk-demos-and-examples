require 'gtk4'

class SearchEntryDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Type to Search'
          win.resizable = false
          win.set_size_request(200, -1)
          win.titlebar = header_bar
          win.child = content_box
        end

        header_bar.tap { |header| header.pack_end(search_toggle) }

        search_toggle.tap do |btn|
          btn.bind_property('active', search_bar, 'search-mode-enabled', :bidirectional)
        end

        content_box.tap do |box|
          box.append(search_bar)
          box.append(result_box)

          search_bar.tap do |bar|
            bar.connect_entry(search_entry)
            bar.show_close_button = false
            bar.child = search_entry
            bar.key_capture_widget = window
          end

          result_box.tap do |rbox|
            rbox.append(result_row)

            result_row.tap do |row|
              row.append(prompt_label)
              row.append(result_label)
            end
          end

          search_entry.tap do |entry|
            entry.signal_connect('search-changed') { result_label.text = entry.text }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.search_entry', :default_flags)
  def window = @window ||= Gtk::Window.new
  def header_bar = @header_bar ||= Gtk::HeaderBar.new
  def content_box = @content_box ||= Gtk::Box.new(:vertical, 0)
  def search_bar = @search_bar ||= Gtk::SearchBar.new
  def search_entry = @search_entry ||= Gtk::SearchEntry.new.tap { |e| e.halign = :center }
  def result_row = @result_row ||= Gtk::Box.new(:horizontal, 10)
  def prompt_label = @prompt_label ||= Gtk::Label.new('Searching for:').tap { |l| l.xalign = 0 }
  def result_label = @result_label ||= Gtk::Label.new('')

  def search_toggle
    @search_toggle ||= Gtk::ToggleButton.new.tap { |btn| btn.icon_name = 'system-search-symbolic' }
  end

  def result_box
    @result_box ||= Gtk::Box.new(:vertical, 18).tap do |box|
      box.margin_start = 18
      box.margin_end = 18
      box.margin_top = 18
      box.margin_bottom = 18
    end
  end
end

SearchEntryDemo.new.build.run
