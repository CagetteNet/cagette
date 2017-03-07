import Common;
import js.JQuery;
/**
 * JS Shopping Cart
 * 
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Cart
{

	public var products : Map<Int,ProductInfo>; //product db
	public var categories : Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>; //categ db
	public var pinnedCategories : Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>; //categ db
	public var order : Order;
	
	var loader : JQuery; //ajax loader gif
	
	//for scroll mgmt
	var cartTop : Int;
	var cartLeft : Int;
	var cartWidth : Int;
	var jWindow : JQuery;
	var cartContainer : JQuery;
	
	var date : String;
	var place : Int;


	public function new() 
	{
		products = new Map();
		order = { products:[] };
		categories = [];
		pinnedCategories = [];
	}
	

	
	public function add(pid:Int) {
		loader.show();
		
		var q = App.j('#productQt' + pid).val();
		var qt = 0.0;
		var p = products.get(pid);
		if (p.hasFloatQt) {
			q = StringTools.replace(q, ",", ".");
			qt = Std.parseFloat(q);
		}else {
			qt = Std.parseInt(q);			
		}
		
		if (qt == null) {
			qt = 1;
		}
		//trace("qté : "+qt);
		
		//add server side
		var r = new haxe.Http('/shop/add/$pid/$qt');
		
		r.onData = function(data:String) {
			
			loader.hide();
			
			var d = haxe.Json.parse(data);
			if (!d.success) js.Browser.alert("Erreur : "+d);
			
			//add locally
			subAdd(pid, qt);
			render();
			
			
		}
		r.request();
		
	}
	
	
	function subAdd(pid, qt:Float ) {
	
		for ( p in order.products) {
			if (p.productId == pid) {
				p.quantity += qt;
				render();
				return;
			}
		}
			
		order.products.push( { productId:pid, quantity:qt } );
	}
	
	/**
	 * Render the shopping cart and total
	 */
	function render() {
		var c = App.j("#cart");
		c.empty();
		
		//render items in shopping cart
		c.append( Lambda.map(order.products, function( x ) {
			var p = products.get(x.productId);
			if (p == null) {
				//the product may have been disabled by an admin
				return "";
			}
			
			var btn = "<a onClick='cart.remove(" + p.id + ")' class='btn btn-default btn-xs' data-toggle='tooltip' data-placement='top' title='Retirer de la commande'><span class='glyphicon glyphicon-remove'></span></a>&nbsp;";
			return "<div class='row'> 
				<div class = 'order col-md-9' > <b> " + x.quantity + " </b> x " + p.name+" </div>
				<div class = 'col-md-3'> "+btn+"</div>			
			</div>";
		}).join("\n") );
		
		
		//compute total price
		var total = 0.0;
		for (p in order.products) {
			var pinfo = products.get(p.productId);
			if (pinfo == null) continue;
			total += p.quantity * pinfo.price;
		}
		var ffilter = new sugoi.form.filters.FloatFilter();
		
		var total = ffilter.filter(Std.string(App.roundTo(total,2)));
		c.append("<div class='total'>TOTAL : "+total+"</div>");
	}






	function findCategoryName(cid:Int):String{

		for ( cg in this.categories ){
			for (c in cg.categs){
				if (cid == c.id) {
					return c.name;
				}
			}
		}
		for ( cg in this.pinnedCategories ){
			for (c in cg.categs){
				if (cid == c.id) {
					return c.name;
				}
			}
		}
		return null;
	}

	/**
	 * Dynamically sort products by categories
	 */
	public function sortProductsBy(){

		//store products by groups
		var groups = new Map<Int,{name:String,products:Array<ProductInfo>}>();
		var pinned = new Map<Int,{name:String,products:Array<ProductInfo>}>();

		var firstCategGroup = this.categories[0].categs;

		//trace(firstCategGroup);
		//trace(pinnedCategories);

		var pList = Lambda.array(products).copy();

		//for ( p in pList) trace(p.name+" : " + p.categories);
		//trace("----------------");

		//sort by categs
		for ( p in pList.copy() ){
			//trace(p.name+" : " + p.categories);
			p.element.remove();

			for ( categ in p.categories){

				if (Lambda.find(firstCategGroup, function(c) return c.id == categ) != null){

					//is in this category group
					var g = groups.get(categ);
					if ( g == null){
						var name = findCategoryName(categ);
						g = {name:name,products:[]};
					}
					g.products.push(p);
					//trace("remove " + p.name);
					pList.remove(p);
					groups.set(categ, g);

				}
				else{
					// is in pinned group ?
					var isInPinnedCateg = false;
					for ( cg in pinnedCategories){
							if (Lambda.find(cg.categs, function(c) return c.id == categ) != null){
								isInPinnedCateg = true;
								break;
							}
					}

					if (isInPinnedCateg){

						var c = pinned.get(categ);
						if ( c == null){

							var name = findCategoryName(categ);
							c = {name:name,products:[]};
						}
						c.products.push(p);
						//trace( "add " + p.name+" in PINNED");
						pList.remove(p);
						pinned.set(categ, c);


					}else{
						//not in the selected categ nor in pinned groups
						continue;
					}
				}
			}
		}

		//if some untagged products remain
		if (pList.length > 0){
			groups.set(0,{name:"Autres",products:pList});
		}
		//trace("----------------");
		//render
		var container = App.j(".shop .body");
		//render firts "pinned" groups , then "groups"
		for ( source in [pinned, groups]){

			for (o in source){

				if (o.products.length == 0) continue;
				container.append("<div class='col-md-12 col-xs-12 col-sm-12 col-lg-12'><div class='catHeader'>" + o.name + "</div></div>");
				for ( p in o.products){
					//trace("GROUP "+o.name+" : "+p.name);
					//if the element has already been inserted, we need to clone it
					if (p.element.parent().length == 0){
						container.append( p.element );
					}else{
						var clone = p.element.clone();
						container.append( clone );
					}


				}
			}
		}
		App.j(".product").show();


	}

	/**
	 * is shopping cart empty ?
	 */
	public function isEmpty(){
		return order.products.length == 0;

	}

	/**
     * submit cart
     */
	public function submit() {
		var req = new haxe.Http("/shop/submit");
		req.onData = function(d) {
			js.Browser.location.href = "/shop/validate/"+place+"/"+date;
			
		}
		req.addParameter("data", haxe.Json.stringify(order));
		req.request(true);
		
	}
	
	/**
	 * filter products by category
	 */
	public function filter(cat:Int) {
		
		//icone sur bouton
		App.j(".tag").removeClass("active").children().remove("span");//clean
		
		var bt = App.j("#tag" + cat);
		bt.addClass("active").prepend("<span class ='glyphicon glyphicon-ok'></span> ");
		
		
		//affiche/masque produits
		for (p in products) {
			if (cat==0 || Lambda.has(p.categories, cat)) {
				App.j(".shop .product" + p.id).fadeIn(300);
			}else {
				App.j(".shop .product" + p.id).fadeOut(300);
			}
		}
		
		
		
		
	}
	
	/**
	 * remove a product from cart
	 * @param	pid
	 */
	public function remove(pid:Int ) {
		
		loader.show();
		
		//add server side
		var r = new haxe.Http('/shop/remove/$pid');
		
		r.onData = function(data:String) {
			
			loader.hide();
			
			var d = haxe.Json.parse(data);
			if (!d.success) js.Browser.alert("Erreur : "+d);
			
			//remove locally
			for ( p in order.products.copy()) {
				if (p.productId == pid) {
					order.products.remove(p);
					render();
					return;
				}
			}
			render();
			
			
		}
		r.request();
		
		
		
		
	}
	
	/**
	 * loads products DB and existing cart in ajax
	 */
	public function init(place:Int,date:String) {

		this.place = place;
		this.date = date;
		
		loader = App.j("#cartContainer #loader");
		
		var req = new haxe.Http("/shop/init/"+place+"/"+date);
		req.onData = function(data) {
			loader.hide();
			
			var data : { 
				products:Array<ProductInfo>,
				categories:Array<{name:String,pinned:Bool,categs:Array<CategoryInfo>}>,
				order:Order } = haxe.Unserializer.run(data);

			//populate local categories lists
			for ( cg in data.categories){
				if (cg.pinned){
					pinnedCategories.push(cg);
				}else{
					categories.push(cg);
				}
			}

			//product DB
			var id : Int = 0;
			for (p in data.products) {
				//catch dom element for further usage
				p.element = App.j(".product"+p.id);

				id = id + 1;
				products.set(id, p);
				
				//trace(p.name+" : " + p.categories);
			}
			//existing order
			for ( p in data.order.products) {
				subAdd(p.productId,p.quantity );
			}
			render();
			
			sortProductsBy();

		}
		req.request();
		
		//scroll mgmt
		/*jWindow = App.j(js.Browser.window);
		cartContainer = App.j("#cartContainer");
		//cartTop = cartContainer.position().top;
		cartLeft = cartContainer.position().left;
		cartWidth = cartContainer.width();
		jWindow.scroll(onScroll);*/
		
	}
	
	/**
	 * keep the cart on top when scrolling
	 * @param	e
	 */
	public function onScroll(e:Dynamic) {
		
		//cart container top position		
		
		if (jWindow.scrollTop() > cartTop) {
			//trace("absolute !");
			cartContainer.addClass("scrolled");
			cartContainer.css('left', Std.string(cartLeft) + "px");			
			cartContainer.css('top', Std.string(cartTop) + "px");
			cartContainer.css('width', Std.string(cartWidth) + "px");
			
		}else {
			cartContainer.removeClass("scrolled");
			cartContainer.css('left',"");
			cartContainer.css('top', "");
			cartContainer.css('width', "");
		}
		
		
		
	}
	
}
