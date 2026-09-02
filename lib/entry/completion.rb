require 'gtk4'

class EntryCompletionDemo
  WORDS = [
    'GNOME', 'gnominious', 'Gnomonic projection', 'Gnosophy',
    'total', 'totally', 'toto', 'tottery', 'totterer', 'Totten trust',
    'Tottenham hotspurs', 'totipotent', 'totipotency', 'totemism',
    'totem pole', 'Totara', 'totalizer', 'totalizator', 'totalitarianism',
    'total parenteral nutrition', 'total eclipse', 'Totipresence',
    'Totipalmi', 'zombie', 'aæx', 'aæy', 'aæz'
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Completion'
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(hint_label)
          box.append(entry)

          entry.tap { |e| e.completion = completion }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.entry_completion', :default_flags)
  def window = @window ||= Gtk::Window.new
  def entry = @entry ||= Gtk::Entry.new

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 12).tap do |box|
      box.margin_start = 18
      box.margin_end = 18
      box.margin_top = 18
      box.margin_bottom = 18
    end
  end

  def hint_label
    @hint_label ||= Gtk::Label.new('Try writing <b>total</b> or <b>gnome</b> for example.').tap do |l|
      l.use_markup = true
    end
  end

  def completion_model
    @completion_model ||= Gtk::ListStore.new(String).tap do |store|
      WORDS.each { |word| store.append[0] = word }
    end
  end

  def completion
    @completion ||= Gtk::EntryCompletion.new.tap do |c|
      c.model = completion_model
      c.text_column = 0
      c.inline_completion = true
      c.inline_selection = true
    end
  end
end

EntryCompletionDemo.new.build.run
