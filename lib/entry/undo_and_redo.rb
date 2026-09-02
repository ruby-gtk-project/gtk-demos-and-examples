require 'gtk4'

class EntryUndoDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Undo and Redo'
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(hint_label)
          box.append(entry)
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.entry_undo', :default_flags)
  def window = @window ||= Gtk::Window.new
  def entry = @entry ||= Gtk::Entry.new.tap { |e| e.enable_undo = true }

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 12).tap do |box|
      box.margin_start = 18
      box.margin_end = 18
      box.margin_top = 18
      box.margin_bottom = 18
    end
  end

  def hint_label
    @hint_label ||= Gtk::Label.new('Use Control+z or Control+Shift+z to undo or redo changes')
  end
end

EntryUndoDemo.new.build.run
