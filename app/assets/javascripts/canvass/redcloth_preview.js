/************************************************************************\
 * File:    redcloth_preview.js                                         *
 *          Hipposoft 2011-2022                                         *
 *                                                                      *
 * Purpose: Support an AJAX based preview of RedCloth (Textile) markup. *
 *                                                                      *
 * History: 18-Feb-2011 (ADH): Created.                                 *
 *          02-Jul-2022 (ADH): Vanilla JS; no jQuery or Prototype.      *
\************************************************************************/

const RedClothPreview =
{
  /* Pass IDs of the source text area, target DIV to contain the generated
   * HTML and the URL to which POST requests will be sent with a parameter
   * of "textile" giving the source text. Plain HTML should be returned
   * from whatever handles this, generated in a way that will be consistent
   * in context with the surrounding markup at the insertion point.
   */

  initialize: function( sourceElement, targetElement, requestURL )
  {
    this.sourceElement = document.getElementById(sourceElement);
    this.targetElement = document.getElementById(targetElement);
    this.requestURL    = requestURL;
    this.requestTimer  = null;

    /* The 'makeRequest' method is called via 'setTimeout' but we want the
     * value of 'this' to be useful within it, so bind that now.
     */

    this.sourceElement.addEventListener('textInput', this);
    // this.sourceElement.addEventListener('blur',   this);
    // this.sourceElement.addEventListener('focus',  this);

    /* Make the request immediately if there is existing data in the form
     * field (for 'edit' views).
     */

    if (this.sourceElement.value != '') {
      this.handleEvent(null);
    }
  },

  /* Schedule an update of the parsed Textfile field if none is currently
   * scheduled. Run for any events via the old-school 'handleEvent' listener
   * which provides a really easy way to get 'this' set sensibly. The input
   * parameter is ignored.
   */

  handleEvent: function(_evnt)
  {
    if (this.requestTimer == null) {
      this.requestTimer = window.setTimeout(
        this.makeRequest.bind(this),
        1000
      );
    }
  },

  /* Internal - make an AJAX request to obtain an HTML equivalent of
   * whatever the source element's text happens to be right now and insert
   * the result into the target element.
   */

  makeRequest: function()
  {
    const self        = this;
    const dataAtStart = '' + this.sourceElement.value;

    fetch(
      this.requestURL,
      {
        method:  'POST',
        cache:   'no-cache',
        headers: {'Content-Type': 'application/json'},
        body:    JSON.stringify({textile: this.sourceElement.value})
      }
    )
    .then(function(response) {
      return response.text();
    })
    .then(function(text) {
      self.targetElement.innerHTML = text;
      self.requestTimer = null;

      if (self.sourceElement.value != dataAtStart) {
        handleEvent();
      }
    })
    .catch(function(e) {
      console.warn(e);
    });
  }
};
