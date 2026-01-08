require 'gtk4'

class ClipboardDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Clipboard'
          win.resizable = true
          win.child = main_box
        end

        main_box.tap do |box|
          box.orientation = :vertical
          box.margin_start = 12
          box.margin_end = 12
          box.margin_top = 12
          box.margin_bottom = 12
          box.spacing = 12

          box.append(instructions_label)
          box.append(source_panel.build)
          box.append(Gtk::Separator.new(:horizontal))
          box.append(dest_panel.build)

          instructions_label.tap do |label|
            label.label = '"Copy" will copy the selected data to the clipboard, "Paste" will show the current clipboard contents.'
            label.wrap = true
            label.max_width_chars = 40
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.clipboard', :default_flags)
  def window = @window ||= Gtk::Window.new
  def main_box = @main_box ||= Gtk::Box.new(:vertical, 0)
  def instructions_label = @instructions_label ||= Gtk::Label.new
  def clipboard = @clipboard ||= Gdk::Display.default.clipboard
  def source_panel = @source_panel ||= SourcePanel.new(clipboard)
  def dest_panel = @dest_panel ||= DestPanel.new(clipboard)
end

class SourcePanel
  def initialize(clipboard)
    @clipboard = clipboard
  end

  def build
    @build ||= Gtk::Box.new(:horizontal, 12).tap do |box|
      box.append(chooser)
      box.append(stack)
      box.append(copy_button)

      chooser.tap do |c|
        c.valign = :center
        c.model = Gtk::StringList.new(['Text', 'Color', 'Image', 'File', 'Folder'])
        c.signal_connect('notify::selected') do
          stack.visible_child_name = %w[Text Color Image File Folder][c.selected]
          update_copy_sensitivity
        end
      end

      stack.tap do |s|
        s.vexpand = true
        s.add_named(text_source.build, 'Text')
        s.add_named(color_source.build, 'Color')
        s.add_named(image_source.build, 'Image')
        s.add_named(file_source.build, 'File')
        s.add_named(folder_source.build, 'Folder')
      end

      copy_button.tap do |btn|
        btn.label = '_Copy'
        btn.use_underline = true
        btn.valign = :center
        btn.signal_connect('clicked') { copy_to_clipboard }
      end

      text_source.on_changed { update_copy_sensitivity }
      update_copy_sensitivity
    end
  end

  def chooser = @chooser ||= Gtk::DropDown.new
  def stack = @stack ||= Gtk::Stack.new
  def copy_button = @copy_button ||= Gtk::Button.new
  def text_source = @text_source ||= TextSource.new
  def color_source = @color_source ||= ColorSource.new
  def image_source = @image_source ||= ImageSource.new
  def file_source = @file_source ||= FileSource.new(-> { update_copy_sensitivity })
  def folder_source = @folder_source ||= FolderSource.new(-> { update_copy_sensitivity })

  def update_copy_sensitivity
    copy_button.sensitive = current_source.can_copy?
  end

  def current_source
    case stack.visible_child_name
    when 'Text' then text_source
    when 'Color' then color_source
    when 'Image' then image_source
    when 'File' then file_source
    when 'Folder' then folder_source
    end
  end

  def copy_to_clipboard
    current_source.copy_to(@clipboard)
  end
end

class DestPanel
  def initialize(clipboard)
    @clipboard = clipboard
  end

  def build
    @build ||= Gtk::Box.new(:horizontal, 12).tap do |box|
      box.append(paste_button)
      box.append(type_label)
      box.append(stack)

      Gtk::DropTarget.new(Gdk::Paintable.gtype, :copy).tap do |drop|
        drop.signal_connect('drop') { |_, value, x, y| present_value(value); true }
        box.add_controller(drop)
      end

      paste_button.tap do |btn|
        btn.label = '_Paste'
        btn.use_underline = true
        btn.signal_connect('clicked') { paste_from_clipboard }
        @clipboard.signal_connect('changed') { update_sensitivity }
      end

      type_label.tap do |label|
        label.xalign = 0
        label.hexpand = true
      end

      stack.tap do |s|
        s.halign = :end
        s.valign = :center
        s.add_named(Gtk::Label.new, '')
        s.add_named(text_dest, 'Text')
        s.add_named(image_dest, 'Image')
        s.add_named(color_dest, 'Color')
        s.add_named(file_dest, 'File')

        text_dest.tap do |label|
          label.halign = :end
          label.ellipsize = :end
        end

        image_dest.tap do |img|
          img.halign = :end
          img.pixel_size = 48
        end

        color_dest.tap do |btn|
          btn.halign = :end
          btn.can_target = false
        end

        file_dest.tap do |label|
          label.halign = :end
          label.ellipsize = :start
        end
      end

      update_sensitivity
    end
  end

  def paste_button = @paste_button ||= Gtk::Button.new
  def type_label = @type_label ||= Gtk::Label.new
  def stack = @stack ||= Gtk::Stack.new
  def text_dest = @text_dest ||= Gtk::Label.new
  def image_dest = @image_dest ||= Gtk::Image.new
  def color_dest = @color_dest ||= Gtk::ColorDialogButton.new(Gtk::ColorDialog.new)
  def file_dest = @file_dest ||= Gtk::Label.new

  def update_sensitivity
    format_string = @clipboard.formats.to_s

    paste_button.sensitive =
      format_string.include?('gchararray') ||
      format_string.include?('Texture') ||
      format_string.include?('Paintable') ||
      format_string.include?('RGBA') ||
      format_string.include?('File')
  end

  def paste_from_clipboard
    format_string = @clipboard.formats.to_s

    gtype = if format_string.include?('Texture')
              Gdk::Texture.gtype
            elsif format_string.include?('Paintable')
              Gdk::Paintable.gtype
            elsif format_string.include?('RGBA')
              Gdk::RGBA.gtype
            elsif format_string.include?('File')
              Gio::File.gtype
            elsif format_string.include?('gchararray')
              GLib::Type["gchararray"]
            end

    if gtype
      @clipboard.read_value_async(gtype, 0, nil) do |_, result|
        gvalue = @clipboard.read_value_finish(result)
        present_value(gvalue.value)
      end
    end
  end

  def present_value(value)
    case value
    when Gdk::Paintable
      stack.visible_child_name = 'Image'
      image_dest.paintable = value
      type_label.label = 'Image'
    when Gdk::RGBA
      stack.visible_child_name = 'Color'
      color_dest.rgba = value
      type_label.label = 'Color'
    when Gio::File
      stack.visible_child_name = 'File'
      file_dest.label = value.path
      type_label.label = 'File'
    when String
      stack.visible_child_name = 'Text'
      text_dest.label = value
      type_label.label = 'Text'
    end
  end
end

class FolderSource
  def initialize(on_changed = nil)
    @folder = nil
    @on_changed = on_changed
  end

  def build
    @build ||= Gtk::Button.new.tap do |btn|
      btn.valign = :center
      btn.child = Gtk::Label.new('—').tap { |l| l.xalign = 0; l.ellipsize = :start }

      Gtk::DragSource.new.tap do |drag|
        drag.propagation_phase = :capture
        drag.signal_connect('prepare') { Gdk::ContentProvider.new_for_value(@folder) if @folder }
        btn.add_controller(drag)
      end

      btn.signal_connect('clicked') { open_dialog }
    end
  end

  def can_copy? = !!@folder

  def copy_to(clipboard)
    clipboard.set(@folder) if @folder
  end

  def open_dialog
    Gtk::FileDialog.new.tap do |dialog|
      dialog.select_folder(build.get_ancestor(Gtk::Window), nil) do |_, result|
        @folder = dialog.select_folder_finish(result)
        build.child.label = @folder.path
        @on_changed&.call
      rescue StandardError
        # User cancelled
      end
    end
  end
end

class TextSource
  def build
    @build ||= Gtk::Entry.new.tap do |entry|
      entry.valign = :center
      entry.text = 'Copy this!'
    end
  end

  def on_changed(&block)
    build.signal_connect('notify::text', &block)
  end

  def can_copy? = !build.text.empty?

  def copy_to(clipboard)
    clipboard.set(build.text)
  end
end

class ColorSource
  def build
    @build ||= Gtk::ColorDialogButton.new(Gtk::ColorDialog.new).tap do |btn|
      btn.valign = :center
    end
  end

  def can_copy? = true

  def copy_to(clipboard)
    clipboard.set(build.rgba)
  end
end

class ImageSource
  ICONS = ['org.gtk.Demo4', 'face-smile-symbolic', 'face-laugh-symbolic'].freeze

  def build
    @build ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.valign = :center
      box.add_css_class('linked')

      ICONS.each_with_index do |icon_name, i|
        Gtk::ToggleButton.new.tap do |btn|
          btn.active = i.zero?
          btn.group = @first_button unless i.zero?
          @first_button ||= btn
          btn.child = Gtk::Image.new(icon_name:, pixel_size: 48)

          Gtk::DragSource.new.tap do |drag|
            drag.signal_connect('prepare') { Gdk::ContentProvider.new_for_value(btn.child.paintable) }
            btn.add_controller(drag)
          end

          box.append(btn)
        end
      end
    end
  end

  def can_copy? = true

  def copy_to(clipboard)
    btn = build.first_child
    while btn
      if btn.active?
        image = btn.child
        paintable = case image.storage_type.nick
                    when "icon-name"
                      icon_theme = Gtk::IconTheme.get_for_display(image.display)
                      p "icon_theme: #{icon_theme}"
                      p "looking up: #{image.icon_name}"
                      result = icon_theme.lookup_icon(image.icon_name, 48)
                      p "lookup result: #{result}"
                      result
                    when "paintable"
                      image.paintable
                    end
        p "paintable: #{paintable}"
        clipboard.set(paintable) if paintable
        break
      end
      btn = btn.next_sibling
    end
  end
end

class FileSource
  def initialize(on_changed = nil)
    @file = nil
    @on_changed = on_changed
  end

  def build
    @build ||= Gtk::Button.new.tap do |btn|
      btn.valign = :center
      btn.child = Gtk::Label.new('—').tap { |l| l.xalign = 0; l.ellipsize = :start }

      Gtk::DragSource.new.tap do |drag|
        drag.propagation_phase = :capture
        drag.signal_connect('prepare') { Gdk::ContentProvider.new_for_value(@file) if @file }
        btn.add_controller(drag)
      end

      btn.signal_connect('clicked') { open_dialog }
    end
  end

  def can_copy? = !!@file

  def copy_to(clipboard)
    clipboard.set(@file) if @file
  end

  def open_dialog
    Gtk::FileDialog.new.tap do |dialog|
      dialog.open(build.get_ancestor(Gtk::Window), nil) do |_, result|
        @file = dialog.open_finish(result)
        build.child.label = @file.path
        @on_changed&.call
      rescue StandardError
        # User cancelled
      end
    end
  end
end

ClipboardDemo.new.build.run
