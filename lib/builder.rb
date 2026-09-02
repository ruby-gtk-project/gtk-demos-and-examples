require 'gtk4'

class BuilderDemo
  PEOPLE = [
    ['John', 'Doe', 25, 'This is the John Doe row'],
    ['Mary', 'Unknown', 50, 'This is the Mary Unknown row']
  ].freeze

  MENU = {
    '_File' => [
      [['_New', 'win.new'], ['_Open', 'win.open'], ['_Save', 'win.save'], ['Save _As', 'win.save-as']],
      [['_Quit', 'win.quit']]
    ],
    '_Edit' => [
      [['_Copy', 'win.copy'], ['_Cut', 'win.cut'], ['_Paste', 'win.paste']]
    ],
    '_Help' => [
      [['_Help', 'win.help'], ['_About', 'win.about']]
    ]
  }.freeze

  # label, tooltip, icon, action — nil marks a separator
  TOOLBAR = [
    ['New', 'Create a new file', 'document-new', 'win.new'],
    ['Open', 'Open a file', 'document-open', 'win.open'],
    ['Save', 'Save a file', 'document-save', 'win.save'],
    nil,
    ['Copy', 'Copy selected object into the clipboard', 'edit-copy', 'win.copy'],
    ['Cut', 'Cut selected object into the clipboard', 'edit-cut', 'win.cut'],
    ['Paste', 'Paste object from the clipboard', 'edit-paste', 'win.paste']
  ].freeze

  CONTROL = Gdk::ModifierType::CONTROL_MASK
  CONTROL_SHIFT = Gdk::ModifierType::CONTROL_MASK | Gdk::ModifierType::SHIFT_MASK
  NO_MODIFIER = 0

  SHORTCUTS = [
    [Gdk::Keyval::KEY_n, CONTROL, 'win.new'],
    [Gdk::Keyval::KEY_o, CONTROL, 'win.open'],
    [Gdk::Keyval::KEY_s, CONTROL, 'win.save'],
    [Gdk::Keyval::KEY_s, CONTROL_SHIFT, 'win.save-as'],
    [Gdk::Keyval::KEY_q, CONTROL, 'win.quit'],
    [Gdk::Keyval::KEY_c, CONTROL, 'win.copy'],
    [Gdk::Keyval::KEY_x, CONTROL, 'win.cut'],
    [Gdk::Keyval::KEY_v, CONTROL, 'win.paste'],
    [Gdk::Keyval::KEY_F1, NO_MODIFIER, 'win.help'],
    [Gdk::Keyval::KEY_F7, NO_MODIFIER, 'win.about']
  ].freeze

  UNIMPLEMENTED = %w[new open save save-as copy cut paste].freeze
  STATUS_TIMEOUT = 5000

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Builder'
          win.set_default_size(440, 250)
          win.child = content_box
          win.insert_action_group('win', actions)
          win.add_controller(shortcut_controller)
        end

        content_box.tap do |box|
          box.append(menu_bar)
          box.append(toolbar)
          box.append(scrolled_window)
          box.append(status_label)

          toolbar.tap do |bar|
            TOOLBAR.each { |item| bar.append(item ? tool_button(*item) : Gtk::Separator.new(:horizontal)) }
          end

          scrolled_window.tap { |sw| sw.child = tree_view }
        end

        shortcut_controller.tap do |controller|
          SHORTCUTS.each do |keyval, modifiers, action|
            controller.add_shortcut(Gtk::Shortcut.new(Gtk::KeyvalTrigger.new(keyval, modifiers),
                                                      Gtk::NamedAction.new(action)))
          end
        end

        register_actions

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.builder', :default_flags)
  def window = @window ||= Gtk::Window.new
  def content_box = @content_box ||= Gtk::Box.new(:vertical, 0)
  def menu_bar = @menu_bar ||= Gtk::PopoverMenuBar.new(menu_model)
  def actions = @actions ||= Gio::SimpleActionGroup.new

  def shortcut_controller
    @shortcut_controller ||= Gtk::ShortcutController.new.tap { |c| c.scope = :global }
  end

  def toolbar
    @toolbar ||= Gtk::Box.new(:horizontal, 0).tap do |bar|
      bar.accessible_role = :toolbar
      bar.add_css_class('toolbar')
    end
  end

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.has_frame = true
      sw.hexpand = true
      sw.vexpand = true
    end
  end

  def status_label
    @status_label ||= Gtk::Label.new.tap do |label|
      label.xalign = 0
      label.margin_start = 2
      label.margin_end = 2
      label.margin_top = 2
      label.margin_bottom = 2
    end
  end

  def menu_model
    @menu_model ||= Gio::Menu.new.tap do |menu|
      MENU.each do |title, sections|
        Gio::Menu.new.tap do |submenu|
          sections.each do |items|
            Gio::Menu.new.tap do |section|
              items.each { |label, action| section.append(label, action) }
              submenu.append_section(nil, section)
            end
          end

          menu.append_submenu(title, submenu)
        end
      end
    end
  end

  def store
    @store ||= Gtk::ListStore.new(String, String, Integer, String).tap do |s|
      PEOPLE.each do |name, surname, age, tooltip|
        s.append.tap do |row|
          row[0] = name
          row[1] = surname
          row[2] = age
          row[3] = tooltip
        end
      end
    end
  end

  def tree_view
    @tree_view ||= Gtk::TreeView.new(store).tap do |view|
      view.tooltip_column = 3
      ['Name', 'Surname', 'Age'].each_with_index do |title, index|
        view.append_column(Gtk::TreeViewColumn.new(title, Gtk::CellRendererText.new, text: index))
      end
    end
  end

  def about_dialog
    @about_dialog ||= Gtk::AboutDialog.new.tap do |dialog|
      dialog.program_name = 'Builder demo'
      dialog.logo_icon_name = 'org.gtk.Demo4'
      dialog.modal = true
      dialog.transient_for = window
      dialog.hide_on_close = true
    end
  end

  private

  def tool_button(label, tooltip, icon_name, action)
    Gtk::Button.new(label: label).tap do |btn|
      btn.tooltip_text = tooltip
      btn.icon_name = icon_name
      btn.action_name = action
    end
  end

  def register_actions
    UNIMPLEMENTED.each do |name|
      add_action(name) { status_message("Action “#{name}” not implemented") }
    end

    add_action('quit') { window.destroy }
    add_action('about') { about_dialog.present }
    add_action('help') { status_message('Help not available') }
  end

  def add_action(name, &handler)
    Gio::SimpleAction.new(name).tap do |action|
      action.signal_connect('activate') { handler.call }
      actions.add_action(action)
    end
  end

  # Shows a message in the status line and clears it again a few seconds later.
  def status_message(text)
    GLib::Source.remove(@status_timeout) if @status_timeout
    status_label.label = text

    @status_timeout = GLib::Timeout.add(STATUS_TIMEOUT) do
      status_label.label = ''
      @status_timeout = nil
      GLib::Source::REMOVE
    end
  end
end

BuilderDemo.new.build.run
