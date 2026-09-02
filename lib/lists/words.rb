require 'gtk4'

# Filtering a very long list. The words come from /usr/share/dict/words when
# it is there, and the filter runs incrementally so that typing stays
# responsive: the progress bar shows how much of the list is still pending.
class WordsDemo
  WORDS_FILE = '/usr/share/dict/words'.freeze

  FALLBACK = 'lorem ipsum dolor sit amet consectetur adipisci elit sed eiusmod ' \
             'tempor incidunt labore et dolore magna aliqua ut enim ad minim ' \
             'veniam quis nostrud exercitation ullamco laboris nisi ut aliquid ' \
             'ex ea commodi consequat'.freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.set_default_size(400, 600)
          win.titlebar = header_bar
          win.child = content_box
        end

        header_bar.tap do |header|
          header.pack_start(open_button)
          open_button.signal_connect('clicked') { choose_file }
        end

        content_box.tap do |box|
          box.append(search_entry)
          box.append(overlay)

          search_entry.tap do |entry|
            entry.signal_connect('search-changed') { word_filter.search = entry.text }
          end

          overlay.tap do |o|
            o.child = scrolled_window
            o.add_overlay(progress_bar)

            scrolled_window.tap { |sw| sw.child = list_view }
          end
        end

        filter_model.tap do |model|
          model.signal_connect('items-changed') { update_title }
          model.signal_connect('notify::pending') { update_title }
        end

        update_title

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.listview_words', :default_flags)
  def window = @window ||= Gtk::Window.new
  def content_box = @content_box ||= Gtk::Box.new(:vertical, 0)
  def overlay = @overlay ||= Gtk::Overlay.new
  def search_entry = @search_entry ||= Gtk::SearchEntry.new
  def list_view = @list_view ||= Gtk::ListView.new(Gtk::NoSelection.new(filter_model), factory)

  def header_bar
    @header_bar ||= Gtk::HeaderBar.new.tap { |header| header.show_title_buttons = true }
  end

  def open_button
    @open_button ||= Gtk::Button.new(label: '_Open').tap { |btn| btn.use_underline = true }
  end

  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new.tap { |sw| sw.vexpand = true }

  def progress_bar
    @progress_bar ||= Gtk::ProgressBar.new.tap do |bar|
      bar.halign = :fill
      bar.valign = :start
      bar.hexpand = true
    end
  end

  def words
    @words ||= Gtk::StringList.new([]).tap do |list|
      if File.readable?(WORDS_FILE)
        load_file(list, WORDS_FILE)
      else
        FALLBACK.split(' ').each { |word| list.append(word) }
      end
    end
  end

  def word_filter
    @word_filter ||= Gtk::StringFilter.new.tap { |f| f.expression = Gtk::PropertyExpression.new(Gtk::StringObject.gtype, nil, 'string') }
  end

  def filter_model
    @filter_model ||= Gtk::FilterListModel.new(words, word_filter).tap { |model| model.incremental = true }
  end

  def factory
    @factory ||= Gtk::SignalListItemFactory.new.tap do |f|
      f.signal_connect('setup') { |_, item| item.child = Gtk::Inscription.new.tap { |i| i.xalign = 0 } }
      f.signal_connect('bind') { |_, item| item.child.text = item.item.string }
    end
  end

  private

  def load_file(list, path)
    File.foreach(path, chomp: true) do |line|
      list.append(line.scrub) unless line.empty?
    end
  end

  def choose_file
    Gtk::FileDialog.new.open(window, nil) do |dialog, result|
      dialog.open_finish(result).then { |file| replace_words(file.path) if file }
    rescue GLib::Error
      nil
    end
  end

  def replace_words(path)
    words.splice(0, words.n_items, [])
    load_file(words, path)
  end

  def update_title
    filter_model.model.n_items.then do |total|
      filter_model.pending.then do |pending|
        progress_bar.visible = !pending.zero?
        progress_bar.fraction = total.positive? ? (total - pending) / total.to_f : 0.0
        window.title = "#{filter_model.n_items} lines"
      end
    end
  end
end

WordsDemo.new.build.run
