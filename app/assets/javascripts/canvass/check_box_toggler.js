/************************************************************************\
 * File:    check_box_toggler.js                                        *
 *          Hipposoft 2008                                              *
 *                                                                      *
 * Purpose: Create a selection list which helps a user change the state *
 *          of (potentially) large numbers of check boxes.              *
 *                                                                      *
 *          To use, call check_box_toggle_field from an inline script.  *
 *                                                                      *
 * History: 12-Jun-2008 (ADH): Created.                                 *
 *          05-Apr-2010 (ADH): Change main API to support an options    *
 *                             hash including allowance for externally  *
 *                             provided menu entry text strings, giving *
 *                             a way to pass alternative translations.  *
\************************************************************************/

/* Write out a selection list entirely in JS which toggles a set of check
 * boxes according to items selected within it. Pass the ID to assign to
 * the SELECT container and a class name which is applied to any of the
 * check boxes that you want to include in the list's actions. In the
 * options hash, all items optional, pass:
 *
 *   selectText:  Text used for first, non-selectable menu entry
 *   allText:     Text used for "All" menu entry
 *   noneText:    Text used for "None" menu entry
 *   invertText:  Text used for "Invert" menu entry
 *   prefix:      Prefix data for HTML string
 *   suffix:      Puffix data for HTML string
 *
 * Options default to no prefix/suffix string and English versions of the
 * menu entry text strings.
 */

function check_box_toggle_field( id, className, options )
{
    if ( ! $$ ) return;

    options            = options            || {};
    options.prefix     = options.prefix     || '';
    options.suffix     = options.suffix     || '';
    options.selectText = options.selectText || 'Select...';
    options.allText    = options.allText    || 'All';
    options.noneText   = options.noneText   || 'None';
    options.invertText = options.invertText || 'Invert';

    var doc = '<select id="' + id + '">'
              + '<option disabled="disabled" selected="selected">' + options.selectText + '</option>'
              + '<option>' + options.allText    + '</option>'
              + '<option>' + options.noneText   + '</option>'
              + '<option>' + options.invertText + '</option>'
            + '</select>';

    doc = options.prefix + doc;
    doc = doc + options.suffix;

    document.write( doc );

    var list = document.getElementById( id );
    if ( ! list ) return;

    new SelectionHandler( list, className );
}

/* Object which handles selection list changes; by using an object, extra
 * information can be carried through by an event and the EventListener
 * interface.
 */

function SelectionHandler( list, className )
{
    this.list      = list;
    this.className = className;

    list.addEventListener( 'change', this, false );
}

/* Handle changes in the selection list */

SelectionHandler.prototype.handleEvent = function( event )
{
    /* Perform the relevant action on the check boxes */

    $$( 'input.' + this.className ).each
    (
        function( box )
        {
            switch ( event.currentTarget.selectedIndex )
            {
                case 1: box.checked = true;          break;
                case 2: box.checked = false;         break;
                case 3: box.checked = ! box.checked; break;
            }
        }
    );

    /* Restore the default selected item in the list */

    event.currentTarget.options[ 0 ].selected = true;
}
