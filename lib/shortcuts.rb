require 'gtk4'

class ShortcutsDemo
  SHORTCUTS = [
    ['Press Ctrl-G', Gdk::Keyval::KEY_g, Gdk::ModifierType::CONTROL_MASK],
    ['Press X', Gdk::Keyval::KEY_x, 0]
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Shortcuts'
          win.set_default_size(200, -1)
          win.resizable = false
          win.child = list_box
        end

        list_box.tap do |list|
          SHORTCUTS.each { |description, keyval, modifiers| list.append(shortcut_row(description, keyval, modifiers)) }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.shortcut_triggers', :default_flags)
  def window = @window ||= Gtk::Window.new

  def list_box
    @list_box ||= Gtk::ListBox.new.tap do |list|
      list.margin_start = 6
      list.margin_end = 6
      list.margin_top = 6
      list.margin_bottom = 6
    end
  end

  private

  # Each row carries its own global shortcut controller, so the key press is
  # picked up wherever the focus happens to be.
  def shortcut_row(description, keyval, modifiers)
    Gtk::Label.new(description).tap do |row|
      row.add_controller(Gtk::ShortcutController.new.tap do |controller|
        controller.scope = :global
        controller.add_shortcut(
          Gtk::Shortcut.new(Gtk::KeyvalTrigger.new(keyval, modifiers),
                            Gtk::CallbackAction.new { puts "activated #{description}"; true })
        )
      end)
    end
  end
end

ShortcutsDemo.new.build.run
