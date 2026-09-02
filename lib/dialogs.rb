require 'gtk4'

# The dialog the "Interactive Dialog" button pops up: it edits copies of the
# main window's entries and only writes them back when OK is pressed.
class InteractiveDialog
  def initialize(parent:, values:, on_accept:)
    @parent = parent
    @values = values
    @on_accept = on_accept
  end

  def build
    @build ||= dialog.tap do |d|
      d.set_default_response(Gtk::ResponseType::OK)
      d.content_area.append(grid)

      grid.tap do |g|
        g.hexpand = true
        g.vexpand = true
        g.halign = :center
        g.valign = :center
        g.row_spacing = 6
        g.column_spacing = 6

        g.attach(first_label, 0, 0, 1, 1)
        g.attach(first_entry, 1, 0, 1, 1)
        g.attach(second_label, 0, 1, 1, 1)
        g.attach(second_entry, 1, 1, 1, 1)
      end

      d.signal_connect('response') do |_, response|
        @on_accept.call(first_entry.text, second_entry.text) if response == Gtk::ResponseType::OK
        d.destroy
      end
    end
  end

  def dialog
    @dialog ||= Gtk::Dialog.new(title: 'Interactive Dialog', parent: @parent,
                                flags: [:modal, :destroy_with_parent, :use_header_bar],
                                buttons: [['_OK', Gtk::ResponseType::OK],
                                          ['_Cancel', Gtk::ResponseType::CANCEL]])
  end

  def grid = @grid ||= Gtk::Grid.new
  def first_entry = @first_entry ||= Gtk::Entry.new.tap { |e| e.text = @values.first }
  def second_entry = @second_entry ||= Gtk::Entry.new.tap { |e| e.text = @values.last }
  def first_label = @first_label ||= mnemonic_label('_Entry 1', first_entry)
  def second_label = @second_label ||= mnemonic_label('E_ntry 2', second_entry)

  private

  def mnemonic_label(text, widget)
    Gtk::Label.new(text).tap do |label|
      label.use_underline = true
      label.mnemonic_widget = widget
    end
  end
end

class DialogsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Dialogs'
          win.resizable = false
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(message_row)
          box.append(Gtk::Separator.new(:horizontal))
          box.append(interactive_row)

          message_row.tap do |row|
            row.append(message_button)
            message_button.signal_connect('clicked') { show_message_dialog }
          end

          interactive_row.tap do |row|
            row.append(interactive_button_box)
            row.append(grid)

            interactive_button_box.tap do |box2|
              box2.append(interactive_button)
              interactive_button.signal_connect('clicked') { show_interactive_dialog }
            end

            grid.tap do |g|
              g.attach(first_label, 0, 0, 1, 1)
              g.attach(first_entry, 1, 0, 1, 1)
              g.attach(second_label, 0, 1, 1, 1)
              g.attach(second_entry, 1, 1, 1, 1)
            end
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.dialogs', :default_flags)
  def window = @window ||= Gtk::Window.new
  def message_row = @message_row ||= Gtk::Box.new(:horizontal, 8)
  def interactive_row = @interactive_row ||= Gtk::Box.new(:horizontal, 8)
  def interactive_button_box = @interactive_button_box ||= Gtk::Box.new(:vertical, 0)
  def message_button = @message_button ||= mnemonic_button('_Message Dialog')
  def interactive_button = @interactive_button ||= mnemonic_button('_Interactive Dialog')
  def first_entry = @first_entry ||= Gtk::Entry.new
  def second_entry = @second_entry ||= Gtk::Entry.new
  def first_label = @first_label ||= mnemonic_label('_Entry 1', first_entry)
  def second_label = @second_label ||= mnemonic_label('E_ntry 2', second_entry)
  def times_shown = @times_shown ||= 0

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 8).tap do |box|
      box.margin_start = 8
      box.margin_end = 8
      box.margin_top = 8
      box.margin_bottom = 8
    end
  end

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.row_spacing = 4
      g.column_spacing = 4
    end
  end

  private

  def mnemonic_button(text)
    Gtk::Button.new(label: text).tap { |btn| btn.use_underline = true }
  end

  def mnemonic_label(text, widget)
    Gtk::Label.new(text).tap do |label|
      label.use_underline = true
      label.mnemonic_widget = widget
    end
  end

  def show_message_dialog
    @times_shown = times_shown + 1

    Gtk::AlertDialog.new.tap do |dialog|
      dialog.message = 'Test message'
      dialog.detail = times_shown == 1 ? 'Has been shown once' : "Has been shown #{times_shown} times"
      dialog.buttons = %w[OK Cancel]
      dialog.show(window)
    end
  end

  def show_interactive_dialog
    InteractiveDialog.new(
      parent: window,
      values: [first_entry.text, second_entry.text],
      on_accept: lambda do |first, second|
        first_entry.text = first
        second_entry.text = second
      end
    ).tap { |dialog| dialog.build.present }
  end
end

DialogsDemo.new.build.run
