/************************************************************************\
 * File:    redcloth_preview.js                                         *
 *          Hipposoft 2011                                              *
 *                                                                      *
 * Purpose: Support an AJAX based preview of RedCloth (Textile) markup. *
 *                                                                      *
 * History: 18-Feb-2011 (ADH): Created.                                 *
\************************************************************************/

if ( $ !== undefined )
{
  var RedClothPreview = Class.create
  (
    {
      /* Pass IDs of the source text area, target DIV to contain the generated
       * HTML and the URL to which POST requests will be sent with a parameter
       * of "textile" giving the source text. Plain HTML should be returned
       * from whatever handles this, generated in a way that will be consistent
       * in context with the surrounding markup at the insertion point.
       */
 
      initialize: function( sourceElement, targetElement, requestURL )
      {
        this.sourceElement = $( sourceElement );
        this.targetElement = $( targetElement );
        this.requestURL    = requestURL;
        this.observer      = new Form.Element.Observer
        (
          this.sourceElement,
          1, /* Update at most every second to lessen server load */
          this.makeRequest.bind( this )
        );

        /* Make the request immediately too - there may be existing data in the
         * form field ('edit' views).
         */

        this.makeRequest( null );
      },

      /* Internal - make an AJAX request to obtain an HTML equivalent of
       * whatever the source element's text happens to be right now and insert
       * the result into the target element.
       *
       * The input parameter is ignored.
       */

      makeRequest: function( event )
      {
        var self = this;

        if ( this.request != undefined )
        {
          /* Awful API; no obvious way to cancel an in-progress request so we
           * could happily flood the server and never know it at this level.
           * Reading the Prototype code, I see it keeps a count of the number
           * of requests - but does nothing with it anywhere, so there seems to
           * be no guard against this.
           *
           * Hence, use an undocumented hack - force the transport level to
           * abort and rely on failure handlers in Prototype to keep its own
           * internal counters correct (hence use of only 'onSuccess' below).
           */

          this.request.transport.abort();
        }

        this.request = new Ajax.Request
        (
          this.requestURL,
          {
            parameters:
            {
              textile: self.sourceElement.value
            },
            onSuccess: function( response )
            {
              self.targetElement.update( response.responseText );
              delete self.request;
            }
          }
        );
      }
    }
  );
}