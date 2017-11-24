import react.ReactMacro.jsx;
import react.*;
import react.store.*;

class App {

	public static var instance : App;
	public var LANG : String;
	public var t : sugoi.i18n.GetText;//gettext translator
	//public var currentBox : ReactComponent.ReactElement; //current react element in the modal window

	function new(?lang="fr") {
		//singleton
		instance = this;
		if(lang!=null) this.LANG = lang;
	}

	/**
	 * Returns a jquery object like $() in javascript
	 * @deprecated
	 */
	public static inline function j(r:Dynamic):js.JQuery {
		return new js.JQuery(r);
	}

	public static inline function jq(r:Dynamic):js.jquery.JQuery{
		return new js.jquery.JQuery(r);
	}

	/**
	 * The JS App will be available as "_" in the document.
	 */
	public static function main() {		
		untyped js.Browser.window._ = new App();
	}

	public function getCart() {
		return new Cart();
	}

	public function getTagger(cid:Int ) {
		return new Tagger(cid);
	}

	public function getTuto(name:String, step:Int) {
		new Tuto(name,step);
	}

	/*public function getProductComposer(){
		//js.Browser.document.addEventListener("DOMContentLoaded", function(event) {
			//ReactDOM.render(jsx('<$ComposerApp/>'), js.Browser.document.getElementById("app"));
		//});
	}*/

	/**
	 * Removes the form element and replace it by a react js component
	 * @param	divId
	 * @param	productName
	 * @param	txpProductId
	 * @param	formName
	 */
	public function getProductInput(divId:String, productName:String, txpProductId:String, formName:String ){

		js.Browser.document.addEventListener("DOMContentLoaded", function(event) {

			//dirty stuff to remove "real" input, and replace it by the react one
			App.j("form input[name='"+formName+"_name']").parent().parent().remove();
			App.j("form select[name='" + formName+"_txpProductId']").parent().parent().remove();

			if (txpProductId == null) txpProductId = "";

			ReactDOM.render(jsx('<$ProductInput productName="$productName" txpProductId="$txpProductId" formName="$formName"/>'),  js.Browser.document.getElementById(divId));
		});
	}

	public function initReportHeader(){
		ReactDOM.render(jsx('<$ReportHeader />'),  js.Browser.document.querySelector('div.reportHeaderContainer'));
	}

	public static function roundTo(n:Float, r:Int):Float {
		return Math.round(n * Math.pow(10,r)) / Math.pow(10,r) ;
	}


	/**
	 * Ajax loads a page and display it in a modal window
	 * @param	url
	 * @param	title
	 */
	public function overlay(url:String,?title,?large=true) {

		if (title != null) title = StringTools.urlDecode(title);

		var r = new haxe.Http(url);
		r.onData = function(data) {

			//setup body and title
			var m = App.j("#myModal");
			m.find(".modal-body").html(data);
			if (title != null) m.find(".modal-title").html(title);

			if (!large) m.find(".modal-dialog").removeClass("modal-lg");


			untyped App.j('#myModal').modal(); //bootstrap 3 modal window

		}
		r.request();
	}

	/**
	 * Displays an ajax login box
	 */
	public function loginBox(redirectUrl:String) {
		var m = App.j("#myModal");
		m.find(".modal-title").html("Connexion");
		m.find(".modal-dialog").removeClass("modal-lg");
		untyped m.modal();
		ReactDOM.render(jsx('<$LoginBox redirectUrl="$redirectUrl" />'),  js.Browser.document.querySelector('#myModal .modal-body'));
		return false;
	}

	public function registerBox(redirectUrl:String,?phoneRequired=false) {
		var m = App.j("#myModal");
		m.find(".modal-title").html("Inscription");
		m.find(".modal-dialog").removeClass("modal-lg");
		untyped m.modal();
		ReactDOM.render(jsx('<$RegisterBox redirectUrl="$redirectUrl" phoneRequired="$phoneRequired"/>'),  js.Browser.document.querySelector('#myModal .modal-body'));
		return false;
	}

	public function shop(place:Int, date:String) {
		ReactDOM.render(jsx('<$Store date=$date place=$place/>'),  js.Browser.document.querySelector('#shop'));
	}

	/**
	 * Helper to get values of a bunch of checked checkboxes
	 * @param	formSelector
	 */
	public function getCheckboxesId(formSelector:String):Array<String>{
		var out = [];
		var checkboxes = js.Browser.document.querySelectorAll(formSelector + " input[type=checkbox]");
		for ( input in checkboxes ){
			var input : js.html.InputElement = cast input;
			if ( input.checked ) out.push(input.value);
		}
		return out;
	}


	#if plugins
	public function getHostedPlugin(){
		return new hosted.js.App();
	}
	#end

	/**
	 * set up a warning message when leaving the page
	 */
	public function setWarningOnUnload(active:Bool, ?msg:String){



		if (active){
			js.Browser.window.addEventListener("beforeunload", warn);
		}else{
			js.Browser.window.removeEventListener("beforeunload", warn);
		}

	}

	function warn(e:js.html.Event) {
		var msg = "Voulez vous vraiment quitter cette page ?";
		//js.Browser.window.confirm(msg);
		untyped e.returnValue = msg; //Gecko + IE
		e.preventDefault();
		return msg; //Gecko + Webkit, Safari, Chrome etc.
	}
}


//require bootstrap JS since it's bundled with browserify
@:jsRequire('bootstrap') extern class Bootstrap{}
//@:jsRequire('jquery') extern class JQ extends js.jquery.JQuery{}
