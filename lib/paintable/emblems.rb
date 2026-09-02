require 'gtk4'
require_relative 'nuclear'

# A paintable that draws one paintable on top of another: an icon with an
# emblem in its top right corner. The emblem can be another icon or anything
# else that can be painted, including an animation.
class EmblemedIcon < GLib::Object
  type_register
  include Gdk::Paintable

  ICON_SIZE = 128

  def initialize(icon_name, emblem)
    super()
    @icon = EmblemedIcon.icon(icon_name)
    @emblem = emblem
    follow_emblem
  end

  def self.icon(name)
    Gtk::IconTheme.get_for_display(Gdk::Display.default).lookup_icon(name, ICON_SIZE, direction: :ltr)
  end

  def self.with_icon(icon_name, emblem_name) = new(icon_name, icon(emblem_name))

  def virtual_do_snapshot(snapshot, width, height)
    @icon.snapshot(snapshot, width, height)

    snapshot.save
    snapshot.translate(Graphene::Point.new(0.5 * width, 0))
    @emblem.snapshot(snapshot, 0.5 * width, 0.5 * height)
    snapshot.restore
  end

  private

  # A moving emblem means this paintable moves too.
  def follow_emblem
    @emblem.signal_connect('invalidate-contents') { invalidate_contents }
  end
end

class EmblemsDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Paintable — Emblems'
          win.set_default_size(300, 200)
          win.child = grid
        end

        grid.tap do |g|
          g.attach(starred_folder, 0, 0, 1, 1)
          g.attach(nuclear_disks, 1, 0, 1, 1)
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.paintable_emblem', :default_flags)
  def window = @window ||= Gtk::Window.new
  def grid = @grid ||= Gtk::Grid.new
  def starred_folder = @starred_folder ||= emblemed(EmblemedIcon.with_icon('folder', 'starred'))

  def nuclear_disks
    @nuclear_disks ||= emblemed(EmblemedIcon.new('drive-multidisk', NuclearAnimation.new(false)))
  end

  private

  def emblemed(paintable)
    Gtk::Image.new(paintable: paintable).tap do |image|
      image.pixel_size = 256
      image.hexpand = true
      image.vexpand = true
    end
  end
end

EmblemsDemo.new.build.run
