require 'gtk4'

class TreeStoreDemo
  Holiday = Data.define(:label, :alex, :havoc, :tim, :owen, :dave, :world)

  def self.holiday(label, alex: false, havoc: false, tim: false, owen: false, dave: false, world: false)
    Holiday.new(label, alex, havoc, tim, owen, dave, world)
  end

  # Everyone's day off, shared by the European hackers when `world` is set.
  MONTHS = {
    'January' => [
      holiday('New Years Day', alex: true, havoc: true, tim: true, owen: true, world: true),
      holiday('Presidential Inauguration', havoc: true, owen: true),
      holiday('Martin Luther King Jr. day', havoc: true, owen: true)
    ],
    'February' => [
      holiday("Presidents' Day", havoc: true, owen: true),
      holiday('Groundhog Day'),
      holiday("Valentine's Day", dave: true, world: true)
    ],
    'March' => [
      holiday('National Tree Planting Day'),
      holiday("St Patrick's Day", world: true)
    ],
    'April' => [
      holiday("April Fools' Day", world: true),
      holiday('Army Day'),
      holiday('Earth Day', world: true),
      holiday("Administrative Professionals' Day")
    ],
    'May' => [
      holiday("Nurses' Day"),
      holiday('National Day of Prayer'),
      holiday("Mothers' Day", world: true),
      holiday('Armed Forces Day'),
      holiday('Memorial Day', alex: true, havoc: true, tim: true, owen: true, world: true)
    ],
    'June' => [
      holiday("June Fathers' Day", world: true),
      holiday('Juneteenth (Liberation Day)'),
      holiday('Flag Day', havoc: true, owen: true)
    ],
    'July' => [
      holiday("Parents' Day", world: true),
      holiday('Independence Day', havoc: true, owen: true)
    ],
    'August' => [
      holiday('Air Force Day'),
      holiday('Coast Guard Day'),
      holiday('Friendship Day')
    ],
    'September' => [
      holiday("Grandparents' Day", world: true),
      holiday('Citizenship Day or Constitution Day'),
      holiday('Labor Day', alex: true, havoc: true, tim: true, owen: true, world: true)
    ],
    'October' => [
      holiday("National Children's Day"),
      holiday("Bosses' Day"),
      holiday('Sweetest Day'),
      holiday("Mother-in-Law's Day"),
      holiday('Navy Day'),
      holiday('Columbus Day', havoc: true, owen: true),
      holiday('Halloween', world: true)
    ],
    'November' => [
      holiday('Marine Corps Day'),
      holiday("Veterans' Day", alex: true, havoc: true, tim: true, owen: true, world: true),
      holiday('Thanksgiving', havoc: true, owen: true)
    ],
    'December' => [
      holiday('Pearl Harbor Remembrance Day'),
      holiday('Christmas', alex: true, havoc: true, tim: true, owen: true, world: true),
      holiday('Kwanzaa')
    ]
  }.freeze

  HOLIDAY_NAME_COLUMN = 0
  ALEX_COLUMN = 1
  HAVOC_COLUMN = 2
  TIM_COLUMN = 3
  OWEN_COLUMN = 4
  DAVE_COLUMN = 5
  VISIBLE_COLUMN = 6
  WORLD_COLUMN = 7

  # Alex and Tim only take the days the whole world takes off, so their
  # toggles are activatable only on world holidays.
  PEOPLE = [
    ['Alex', ALEX_COLUMN, :alex, true],
    ['Havoc', HAVOC_COLUMN, :havoc, false],
    ['Tim', TIM_COLUMN, :tim, true],
    ['Owen', OWEN_COLUMN, :owen, false],
    ['Dave', DAVE_COLUMN, :dave, false]
  ].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Tree Store'
          win.set_default_size(650, 400)
          win.child = content_box
        end

        content_box.tap do |box|
          box.append(title_label)
          box.append(scrolled_window)

          scrolled_window.tap { |sw| sw.child = tree_view }

          tree_view.tap do |view|
            add_columns(view)
            view.signal_connect('realize') { view.expand_all }
          end
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.tree_store', :default_flags)
  def window = @window ||= Gtk::Window.new
  def title_label = @title_label ||= Gtk::Label.new("Jonathan's Holiday Card Planning Sheet")

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 8).tap do |box|
      box.margin_start = 8
      box.margin_end = 8
      box.margin_top = 8
      box.margin_bottom = 8
    end
  end

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.has_frame = true
      sw.set_policy(:automatic, :automatic)
    end
  end

  def model
    @model ||= Gtk::TreeStore.new(String, TrueClass, TrueClass, TrueClass,
                                  TrueClass, TrueClass, TrueClass, TrueClass).tap do |store|
      MONTHS.each do |month, holidays|
        store.append(nil).tap do |month_row|
          month_row[HOLIDAY_NAME_COLUMN] = month
          PEOPLE.each { |_, column, _, _| month_row[column] = false }
          month_row[VISIBLE_COLUMN] = false
          month_row[WORLD_COLUMN] = false

          holidays.each do |holiday|
            store.append(month_row).tap do |row|
              row[HOLIDAY_NAME_COLUMN] = holiday.label
              PEOPLE.each { |_, column, field, _| row[column] = holiday.public_send(field) }
              row[VISIBLE_COLUMN] = true
              row[WORLD_COLUMN] = holiday.world
            end
          end
        end
      end
    end
  end

  def tree_view
    @tree_view ||= Gtk::TreeView.new(model).tap do |view|
      view.vexpand = true
      view.selection.mode = :multiple
    end
  end

  private

  def add_columns(view)
    Gtk::CellRendererText.new.tap { |r| r.xalign = 0.0 }.then do |renderer|
      Gtk::TreeViewColumn.new('Holiday', renderer, text: HOLIDAY_NAME_COLUMN).tap do |column|
        column.clickable = true
        view.append_column(column)
      end
    end

    PEOPLE.each { |title, index, _, world_only| add_person_column(view, title, index, world_only) }
  end

  def add_person_column(view, title, index, world_only)
    Gtk::CellRendererToggle.new.tap do |renderer|
      renderer.xalign = 0.0
      renderer.signal_connect('toggled') { |_, path| toggle(path, index) }

      { 'active' => index, 'visible' => VISIBLE_COLUMN }
        .then { |attrs| world_only ? attrs.merge('activatable' => WORLD_COLUMN) : attrs }
        .then do |attributes|
          Gtk::TreeViewColumn.new(title, renderer, attributes).tap do |column|
            column.sizing = :fixed
            column.clickable = true
            view.append_column(column)
          end
        end
    end
  end

  def toggle(path, index)
    model.get_iter(Gtk::TreePath.new(path)).tap { |row| row[index] = !row[index] }
  end
end

TreeStoreDemo.new.build.run
