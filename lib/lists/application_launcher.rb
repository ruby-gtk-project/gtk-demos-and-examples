require 'gtk4'

# A fancy application launcher, and a small introduction to list views: a
# model of GAppInfos, a factory that turns each one into a row, and an
# activate handler that launches whatever was double-clicked.
class ApplicationLauncherDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Application Launcher'
          win.set_default_size(640, 320)
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = list_view }

        list_view.tap do |list|
          list.signal_connect('activate') { |_, position| launch(applications.get_item(position)) }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.listview_applauncher', :default_flags)
  def window = @window ||= Gtk::Window.new
  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new
  def list_view = @list_view ||= Gtk::ListView.new(Gtk::SingleSelection.new(applications), factory)

  # GAppInfo predates GListModel, so the list of applications has to be
  # copied into a store by hand.
  def applications
    @applications ||= Gio::ListStore.new(Gio::AppInfo.gtype).tap do |store|
      Gio::AppInfo.all.each { |info| store.append(info) }
    end
  end

  def factory
    @factory ||= Gtk::SignalListItemFactory.new.tap do |f|
      f.signal_connect('setup') do |_, item|
        item.child = Gtk::Box.new(:horizontal, 12).tap do |box|
          box.append(Gtk::Image.new.tap { |image| image.icon_size = :large })
          box.append(Gtk::Label.new(''))
        end
      end

      f.signal_connect('bind') do |_, item|
        item.item.then do |info|
          item.child.first_child.tap do |image|
            image.gicon = info.icon
            image.next_sibling.label = info.display_name
          end

          item.accessible_label = info.display_name
        end
      end
    end
  end

  private

  def launch(info)
    info.launch(nil, window.display.app_launch_context)
  rescue GLib::Error => error
    Gtk::AlertDialog.new.tap do |dialog|
      dialog.message = "Could not launch #{info.display_name}"
      dialog.detail = error.message
      dialog.show(window)
    end
  end
end

ApplicationLauncherDemo.new.build.run
