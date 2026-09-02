# Findings

Things about the Ruby GTK4 bindings that cost time while porting the demos in
this repository, written down so the next port does not have to rediscover
them. Everything below was hit in practice and the workaround shown is the one
the ported demos actually use.

Versions these were observed with:

| | |
|---|---|
| Ruby | 3.4.9 |
| `gtk4` / `glib2` / `gobject-introspection` gems | 4.3.7 |
| GTK | 4.22.4 |

The general rule: **when a constructor fails, try no-args plus setters, then
positional arguments in the order the error message prints.** The error the
bindings raise lists the signatures they will accept, and that list is the
authority — not the C documentation.

---

## Constructors that do not take what you would expect

### `Gtk::AlertDialog.new` takes no arguments

The C API is `gtk_alert_dialog_new ("message")`, so the obvious port is wrong,
and it fails at the point the dialog is *shown* rather than at load time — easy
to miss if the demo only opens the dialog on a button press.

```ruby
# Wrong: ArgumentError, wrong number of arguments (given 1, expected 0)
Gtk::AlertDialog.new('Keyboard navigation')

# Right
Gtk::AlertDialog.new.tap do |dialog|
  dialog.message = 'Keyboard navigation'
  dialog.detail = 'The term keynav is a shorthand for keyboard navigation...'
  dialog.show(window)
end
```

Used in `lib/links.rb`, `lib/info_bars.rb`, `lib/dialogs.rb`.

### `Gtk::DropDown.new` wants a positional array

Both keyword forms the error message advertises are rejected; only a bare array
of strings works.

```ruby
Gtk::DropDown.new(strings: %w[Red Green Blue])  # fails
Gtk::DropDown.new(model: Gtk::StringList.new(%w[Red Green Blue]))  # fails
Gtk::DropDown.new(%w[Red Green Blue])           # works
Gtk::DropDown.new.tap { |dd| dd.model = Gtk::StringList.new(%w[Red Green Blue]) }  # also works
```

Used in `lib/size_groups.rb`, `lib/text_view/multiple_views.rb`.

### `Gtk::Video.new` wants a positional path or `Gio::File`

```ruby
Gtk::Video.new(filename: path)  # fails, despite being listed as a signature
Gtk::Video.new(path)            # works
```

Used in `lib/images.rb`.

### `Gtk::StringFilter.new(expression)` works, the keyword form crashes

The keyword form does not raise cleanly — it emits
`g_object_ref: assertion 'G_IS_OBJECT (object)' failed` and leaves you with a
filter that does nothing. No-args plus the setter is the safest form.

```ruby
Gtk::StringFilter.new.tap do |filter|
  filter.expression = Gtk::PropertyExpression.new(Gtk::StringObject.gtype, nil, 'string')
end
```

Used in `lib/lists/words.rb`.

### `Graphene::Point3D.new` takes no arguments

`Graphene::Point` and `Graphene::Rect` accept their coordinates positionally;
`Graphene::Point3D` does not, and has to be filled in with `#init`.

```ruby
Graphene::Point.new(x, y)                                   # fine
Graphene::Point3D.new.tap { |point| point.init(x, y, z) }   # the only way
```

Also note the class is `Graphene::Vec3`, not `Graphene::Vector3`, and the axis
constants are class methods: `Graphene::Vec3.x_axis`.

Used in `lib/fixed_layout/cube.rb`.

### `Gdk::Cursor.new` is entirely positional

```ruby
Gdk::Cursor.new('default')                          # named
Gdk::Cursor.new(texture, hotspot_x, hotspot_y)      # image
Gdk::Cursor.new('default', fallback_cursor)         # named with fallback
Gdk::Cursor.new(texture, hotspot_x, hotspot_y, fallback_cursor)
```

Used in `lib/cursors.rb`.

### Construct-only properties need `new!`

`GtkGestureSwipe:n-points` is construct-only, so the setter refuses it, and
`Gtk::GestureSwipe.new` accepts no arguments at all. `GLib::Object.new!` is the
escape hatch — it passes properties straight through to `g_object_new`.

```ruby
Gtk::GestureSwipe.new!('n-points' => 3)
```

Used in `lib/gestures.rb`.

### `Gtk::ShortcutTrigger.parse_string` does not exist

Build the trigger objects directly instead of parsing an accelerator string.

```ruby
Gtk::KeyvalTrigger.new(Gdk::Keyval::KEY_s,
                       Gdk::ModifierType::CONTROL_MASK | Gdk::ModifierType::SHIFT_MASK)
```

Used in `lib/builder.rb`, `lib/shortcuts.rb`.

---

## Defining your own widgets and paintables

Both work well once the two rules below are respected, which between them
unlock a large share of the demos.

### Virtual functions use a `virtual_do_` prefix

Subclass, call `type_register`, and implement the vfunc with `virtual_do_`
prepended to its C name. The class name has to be at least three characters
long or `type_register` fails.

```ruby
class ReadMore < Gtk::Widget
  type_register

  def virtual_do_get_request_mode = Gtk::SizeRequestMode::HEIGHT_FOR_WIDTH

  # Returns [minimum, natural, minimum_baseline, natural_baseline]
  def virtual_do_measure(orientation, for_size) = label.measure(orientation, for_size)

  def virtual_do_size_allocate(width, height, baseline)
    label.allocate(width, height, baseline)   # not a Gdk::Rectangle
  end
end
```

Note `Gtk::Widget#allocate` takes `(width, height, baseline)` and an optional
transform, not an allocation rectangle.

`Gtk::Orientation` has no `#horizontal?`; compare `orientation.nick` against
`'horizontal'`.

Used in `lib/read_more.rb`, `lib/constraints/*.rb`.

### Implementing an interface: `type_register` **before** `include`

This one is silent. Include the interface first and the type registers without
it, and you only find out when something rejects your object with
`must be <GdkPaintable> object`.

```ruby
class NuclearIcon < GLib::Object
  type_register              # must come first
  include Gdk::Paintable

  def virtual_do_snapshot(snapshot, width, height)
    Nuclear.snapshot(snapshot, black, yellow, width, height, @rotation)
  end
end
```

Check it with `NuclearIcon.gtype.interfaces` — an empty array means the include
came too early.

`virtual_do_get_flags` cannot be implemented: returning `Gdk::PaintableFlags`
raises `TODO: Gdk::get_flags: out raw result(interface)[flags]`. Leave it out
and accept the default flags; it is only an optimisation hint.

Used in `lib/paintable/*.rb`, `lib/lists/clocks.rb`.

### Custom layouts do not need a class-level layout manager type

`gtk_widget_class_set_layout_manager_type` has no binding, but setting the
instance property does the same job:

```ruby
self.layout_manager = Gtk::ConstraintLayout.new
```

---

## APIs that are unavailable or broken

### `Gtk::TreeModelFilter#set_modify_func` segfaults

Computing extra columns with a modify function crashes the process as soon as a
**second** view is attached to the same child store. Either view works on its
own; together they reliably die inside the callback, with or without GC
enabled, and even when the callback body is a constant.

`lib/tree_view/filter_model.rb` therefore derives its computed columns in the
cell data functions instead. The visible behaviour is the same; only the API
being demonstrated changes.

`set_visible_func` is fine — but the iter it hands you has no model attached, so
use `model.get_value(iter, column)` rather than `iter[column]`.

### `Gtk::ConstraintLayout#add_constraints_from_description` cannot be called

The Visual Format Language entry point takes a `GHashTable` of widgets, which
the bindings cannot marshal:
`TODO: Ruby -> GIArgument(GHash)[value][interface][interface]`.

`lib/constraints/vfl.rb` keeps the VFL in a comment and spells out the
constraints it stands for.

### `Gtk::TextBuffer` child anchors

`insert` and `insert_child_anchor` both dispatch to `insert_text_child_anchor_raw`,
which the bindings never define. The raw inserter works:

```ruby
buffer.insert_child_anchor_raw(iter, anchor)
```

`create_child_anchor(iter)` is unaffected and is the better choice when you do
not need to build the anchor yourself.

Used in `lib/text_view/hypertext.rb`.

### `Gtk::Expression` bindings are awkward, `bind_property` transforms do not fire

`Gtk::Expression#bind` exists, but `Gtk::ConstantExpression.new` rejects the
argument forms needed to build a chain from a list item.

Separately, the block passed to `GLib::Object#bind_property` is not used to
transform the value — the target gets the raw value, so a `Float` lands in a
label as `"4.250000"`. Connect to the source's change signal and set the target
yourself when the value needs formatting.

Used in `lib/spin_buttons.rb`, `lib/lists/clocks.rb`.

### PangoCairo shape renderers

`pango_cairo_context_set_shape_renderer` has no binding, so custom-drawn
glyph substitutes are not possible. `lib/pango/rotated_text.rb` draws the
ordinary `♥` character instead of the cairo heart the C demo paints.

### `Gtk::Svg` state introspection

`gtk_svg_get_n_states` is not bound, `GTK_SVG_STATE_EMPTY` is not exported (it
is `(guint) -1`, i.e. `(2**32) - 1`), and `state_names` returns `[nil, 0]`
whatever file is loaded. `lib/paintable/svg.rb` toggles the first state rather
than walking through all of them.

### `GLib.monotonic_time` is missing

Use `Process.clock_gettime(Process::CLOCK_MONOTONIC)`, which returns seconds
directly rather than microseconds.

Used in `lib/fixed_layout/transformations.rb`.

---

## Signatures worth memorising

| Call | Ruby form |
|---|---|
| `gtk_icon_theme_lookup_icon` | `theme.lookup_icon(name, size, scale: 1, direction: :ltr, flags: nil)` |
| `gtk_css_provider_load_from_*` | `provider.load(string:)` / `load(path:)` / `load(resource_path:)` |
| `gtk_image_new_from_*` | `Gtk::Image.new(paintable:)` / `(file:)` / `(icon_name:)` / `(icon:)` — positional is deprecated |
| `gtk_text_buffer_get_iter_at_offset` | `buffer.get_iter_at(offset: n)`, also `(mark:)`, `(line:, index:)` |
| `gtk_text_buffer_insert_paintable` | `buffer.insert(iter, paintable)` |
| `g_object_bind_property` flags | `GLib::BindingFlags::BIDIRECTIONAL \| GLib::BindingFlags::SYNC_CREATE` — a bare symbol only works for a single flag |
| `GLib::DateTime` in a zone | `GLib::DateTime.now(GLib::TimeZone.new('Europe/Berlin'))`; the keyword is `timezone:`, not `time_zone:` |
| `gdk_texture_new_from_resource` | `Gdk::Texture.new(Gio::Resources.lookup_data('/org/gtk/libgdk/cursor/default'))` |
| `gtk_text_buffer_get_insert` | `buffer.get_mark('insert')` — there is no `#get_insert` |

`Gtk::InfoBar#default_response=` calls through to `gtk_window_set_default_widget`
on the bar's root, so it has to be set *after* the info bar has been added to a
window, not while the bar is being built.

---

## Environment notes

These are not binding problems, but they look like ones.

- **`Gtk::Video` aborts without GStreamer.** With no media backend installed
  the process dies with `GstPlay: 'playbin3' element not found` — a `g_error`,
  so it cannot be rescued. Run with `GTK_MEDIA=none` on machines without the
  GStreamer base and good plugins. Affects `lib/images.rb` and the video player.
- **Pango markup can out-run GtkTextTag.** Loading `markup.txt` emits
  `GtkTextTag has no property named 'font_scale'` / `'baseline_shift'`. This
  comes from GTK's own markup-to-tag conversion, not from the port, and it is
  harmless — the attributes are simply dropped.
- **The demos need their assets.** Ports load images, CSS and text from
  `demos/gtk-demo/`, since the gresource bundle the C demos use is not built
  here. CSS files are rewritten on load, turning `resource://.../file.png` into
  a `file://` URL under that directory — see `lib/theming/css_editor.rb`.

---

## Testing the ports

Each demo is a standalone application, so it can be smoke-tested by launching
it under a virtual X server and checking that it is still alive when it gets
killed:

```sh
Xvfb :99 -screen 0 1280x900x24 &
DISPLAY=:99 GDK_BACKEND=x11 timeout -s KILL 4 ruby lib/some_demo.rb
# exit status 137 (killed by the timeout) means it started and stayed up
```

This catches far more than a syntax check: draw functions, list factories and
paintable snapshots all run during the first frame, so most callback-level
mistakes surface. It does **not** cover code that only runs on a click — the
`Gtk::AlertDialog` constructor above slipped through exactly that gap — so
exercise interactive paths by hand or by driving them from a timeout.
