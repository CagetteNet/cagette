package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * a product order 
 */
class UserContract extends Object
{

	public var id : SId;
	
	@formPopulate("populate") @:relation(userId)
	public var user : User;
	#if neko
	public var userId: SInt;
	#end
	
	//shared order
	@formPopulate("populate") @:relation(userId2)
	public var user2 : SNull<User>;
	#if neko
	public var userId2: SNull<SInt>;
	#end
	
	public var quantity : SFloat;
	
	@formPopulate("populateProducts") @:relation(productId)
	public var product : Product;
	#if neko
	public var productId : SInt;
	#end
	
	//store price (1 unit price) and fees (percentage not amount ) rate when the order is done
	public var productPrice : SFloat;
	public var feesRate : SInt; //fees in percentage
	
	public var paid : SBool;
	
	//if not null : varying orders
	@:relation(distributionId)
	public var distribution:SNull<db.Distribution>;
	#if neko
	public var distributionId : SNull<SInt>;
	#end
	@:relation(basketId)
	public var basket:SNull<db.Basket>;
	
	public var date : SDateTime;	
	public var flags : SFlags<OrderFlags>;
	
	public function new() 
	{
		super();
		quantity = 1;
		paid = false;
		date = Date.now();
		flags = cast 0;
	}
	
	public function populate() {
		return App.current.user.getAmap().getMembersFormElementData();
	}
	
	
	/**
	 * For shared alternated orders in AMAP contracts
	 * @param	distrib
	 * @return	false -> user , true -> user2
	 */
	public function getWhosTurn(distrib:Distribution) {
		if (distrib == null) throw "distribution is null";
		if (user2 == null) throw "this contract is not shared";
		
		//compter le nbre de distrib pour ce contrat
		var c = Distribution.manager.count( $contract == product.contract && $date >= product.contract.startDate && $date <= distrib.date);		
		var r = c % 2 == 0;
		if (flags.has(InvertSharedOrder)){
			return !r;
		}else{
			return r;
		}
	}
	
	override public function toString() {
		return quantity + "x" + product.name;
	}
	
	public function hasInvertSharedOrder():Bool{
		return flags.has(InvertSharedOrder);
	}
	
	/**
	 * Prepare un dataset simple pret pour affichage ou export csv.
	 */
	public static function prepare(orders:Iterable<db.UserContract>):Array<UserOrder> {
		var out = new Array<UserOrder>();
		var orders = Lambda.array(orders);
		
		for (o in orders) {
		
			var x : UserOrder = cast { };
			x.id = o.id;
			x.userId = o.user.id;
			x.userName = o.user.getCoupleName();
			x.userEmail = o.user.email;
			
			//shared order
			if (o.user2 != null){
				x.userId2 = o.user2.id;
				x.userName2 = o.user2.getCoupleName();
				x.userEmail2 = o.user2.email;
			}
			
			x.productId = o.product.id;
			x.productRef = o.product.ref;
			x.productName = o.product.getName();
			x.productPrice = o.product.price;
			x.productImage = o.product.getImage();
			
			x.quantity = o.quantity;
			x.subTotal = o.quantity * o.product.price;

			var c = o.product.contract;
			
			if ( o.feesRate!=0 ) {
				
				x.fees = x.subTotal * (o.feesRate/100);
				x.percentageName = c.percentageName;
				x.percentageValue = o.feesRate;
				x.total = x.subTotal + x.fees;
				
			}else {
				x.total = x.subTotal;
			}
			x.paid = o.paid;
			
			x.contractId = c.id;
			x.contractName = c.name;
			x.canModify = o.canModify(); 
			
			out.push(x);
			
		}
		
		
		//order by lastname (+lastname2 if exists), then contract
		out.sort(function(a, b) {
			
			if (a.userName + a.userId + a.userName2 + a.userId2 + a.contractId > b.userName + b.userId + b.userName2 + b.userId2 + b.contractId ) {
				
				return 1;
			}
			if (a.userName + a.userId + a.userName2 + a.userId2 + a.contractId < b.userName + b.userId + b.userName2 + b.userId2 + b.contractId ) {
				 
				return -1;
			}
			return 0;
		});
		
		return out;
	}
	
	/**
	 * On peut modifier si ça na pas deja été payé + commande encore ouvertes
	 */
	function canModify():Bool {
	
		var can = false;
		if (this.product.contract.type == db.Contract.TYPE_VARORDER) {
			
			if (this.distribution.orderStartDate == null) {
				can = true;
			}else {
				var n = Date.now().getTime();
				can = n > this.distribution.orderStartDate.getTime() && n < this.distribution.orderEndDate.getTime();
				
			}
			
			
		}else {
		
			can = this.product.contract.isUserOrderAvailable();
			
		}
		
		return can && !this.paid;
		
	}
	
	/**
	 * Store a product Order
	 * 
	 * @param	quantity
	 * @param	productId
	 */
	public static function make(user:db.User, quantity:Float, product:db.Product, ?distribId:Int,?paid:Bool,?user2:db.User,?invert:Bool):db.UserContract {
		
		//checks
		if (quantity <= 0) return null;
		
		//vérifie si il n'y a pas de commandes existantes avec les memes paramètres
		var prevOrders = new List<db.UserContract>();
		
		if (distribId == null) {
			prevOrders = db.UserContract.manager.search($product==product && $user==user, true);
		}else {
			prevOrders = db.UserContract.manager.search($product==product && $user==user && $distributionId==distribId, true);
		}
		
		var o = new db.UserContract();
		o.productId = product.id;
		o.quantity = quantity;
		o.productPrice = product.price;
		if (product.contract.hasPercentageOnOrders()) {
			o.feesRate = product.contract.percentageValue;
		}
		o.user = user;
		if (user2 != null) {
			o.user2 = user2;
			if (invert != null) o.flags.set(InvertSharedOrder);
		}
		if (paid != null) o.paid = paid;
		if (distribId != null) o.distributionId = distribId;
		
		if (prevOrders.length > 0) {
			for (prevOrder in prevOrders) {
				if (!prevOrder.paid) {
					o.quantity += prevOrder.quantity;
					prevOrder.delete();
				}
			}
		}
		
		if (distribId != null){
			var dist = db.Distribution.manager.get(o.distributionId, false);
			var basket = db.Basket.getOrCreate(user, dist.place, dist.date);			
			o.basket = basket;
		}
		
		o.insert();
		
		//stocks
		if (o.product.stock != null) {
			var c = o.product.contract;
			if (c.hasStockManagement()) {
				if (o.product.stock == 0) {
					App.current.session.addMessage("Il n'y a plus de '" + o.product.name + "' en stock, nous l'avons donc retiré de votre commande", true);
					o.delete();
					return null;
					
				}else if (o.product.stock - quantity < 0) {
					var canceled = quantity - o.product.stock;
					o.quantity -= canceled;
					o.update();
					
					App.current.session.addMessage("Nous avons réduit votre commande de '" + o.product.name + "' à "+o.quantity+" articles car il n'y a plus de stock disponible", true);
					o.product.lock();
					o.product.stock = 0;
					o.product.update();
					
				}else {
					o.product.lock();
					o.product.stock -= quantity;
					o.product.update();	
				}
				
			}	
		}
		
		return o;
	}
	
	
	/**
	 * Edit an existing order (quantity)
	 */
	public static function edit(order:db.UserContract, newquantity:Float, ?paid:Bool , ?user2:db.User,?invert:Bool) {
		
		order.lock();
		
		if (newquantity == null) newquantity = 0;
		
		//paid
		if (paid != null) {
			order.paid = paid;
		}else {
			if (order.quantity < newquantity) order.paid = false;	
		}
		
		//shared order
		if (user2 != null){
			order.user2 = user2;	
			if (invert == true) order.flags.set(InvertSharedOrder);
			if (invert == false) order.flags.unset(InvertSharedOrder);
		}else{
			order.user2 = null;
			order.flags.unset(InvertSharedOrder);
		}
		
		//stocks
		if (order.product.stock != null) {
			var c = order.product.contract;
			
			if (c.hasStockManagement()) {
				
				
				if (newquantity < order.quantity) {
					
					//on commande moins que prévu : incrément de stock						
					order.product.lock();
					order.product.stock +=  (order.quantity-newquantity);
					order.product.update();
					
				}else {
				
					//on commande plus que prévu : décrément de stock
					
					var addedquantity = newquantity - order.quantity;
					
					if (order.product.stock - addedquantity < 0) {
						//modification de commande
						newquantity = order.quantity + order.product.stock;
						
						App.current.session.addMessage("Nous avons réduit votre commande de '" + order.product.name + "' à "+newquantity+" articles car il n'y a plus de stock disponible", true);
						order.product.lock();
						order.product.stock = 0;
						order.product.update();
						
					}else {
						order.product.lock();
						order.product.stock -= addedquantity;
						order.product.update();	
					}
					
				}
				
			}	
		}
		
		if (newquantity == 0) {
			order.delete();
			return null;
		}else {
			order.quantity = newquantity;
			order.update();	
			return order;
		}
		
		
	}
	
	/**
	 * Get orders grouped by products. 
	 */
	public static function getOrdersByProduct( options:{?distribution:db.Distribution,?startDate:Date,?endDate:Date}, ?csv = false):List<Dynamic>{
		var view = App.current.view;
		//var pids = db.Product.manager.search($contract == d.contract, false);
		//var pids = Lambda.map(pids, function(x) return x.id);
		
		var orders : List<Dynamic>;
		var where = "";
		var exportName = "";
		
		//options
		if (options.distribution != null){
			
			//by distrib
			var d = options.distribution;
			exportName = "Distribution "+d.contract.name+" du " + d.date.toString().substr(0, 10);
			where += ' and p.contractId = ${d.contract.id}';
			if (d.contract.type == db.Contract.TYPE_VARORDER ) {
				where += ' and up.distributionId = ${d.id}';
			}
			
		}else if(options.startDate!=null && options.endDate!=null){
			
			//by dates
			//exportName = "Distribution "+d.contract.name+" du " + d.date.toString().substr(0, 10);
			
			
		}
			
		var sql = 'select 
				SUM(quantity) as quantity,
				p.id as pid,
				p.name as pname,
				p.price as price,
				p.ref as ref,
				SUM(quantity*up.productPrice) as total
			from UserContract up, Product p 
			where up.productId = p.id 
			$where
			group by p.id order by pname asc; ';
			
		orders = sys.db.Manager.cnx.request(sql).results();	
		
		//populate with full product names
		for ( o in orders){
			var p = db.Product.manager.get(o.pid, false);
			Reflect.setField(o, "pname", p.getName());
		}
		
		
		if (csv) {
			var data = new Array<Dynamic>();
			
			for (o in orders) {
				data.push({
					"quantity":view.formatNum(o.quantity),
					"pname":o.pname,
					"ref":o.ref,
					"price":view.formatNum(o.price),
					"total":view.formatNum(o.total)					
				});				
			}

			sugoi.tools.Csv.printCsvData(data, ["quantity", "pname","ref", "price", "total"],"Export-"+exportName+"-par produits");
			return null;
		}else{
			return orders;		
		}
	}
	
	/**
	 * get users orders for a distribution
	 */
	public static function getOrders(contract:db.Contract, ?distribution:db.Distribution, ?csv = false):Array<UserOrder>{
		var view = App.current.view;
		var orders = new Array<db.UserContract>();
		if (contract.type == db.Contract.TYPE_VARORDER ) {
			orders = contract.getOrders(distribution);	
		}else {
			orders = contract.getOrders();
		}
		
		var orders = db.UserContract.prepare(Lambda.list(orders));
		
		//CSV export
		if (csv) {
			var data = new Array<Dynamic>();
			
			for (o in orders) {
				data.push( { 
					"name":o.userName,
					"productName":o.productName,
					"price":view.formatNum(o.productPrice),
					"quantity":o.quantity,
					"fees":view.formatNum(o.fees),
					"total":view.formatNum(o.total),
					"paid":o.paid
				});				
			}
			
			var exportName = "";
			if (distribution != null){
				exportName = contract.amap.name+" - Distribution "+contract.name+" du " + distribution.date.toString().substr(0, 10);	
			}else{
				exportName = contract.amap.name+" - "+contract.name;
			}
			
			sugoi.tools.Csv.printCsvData(data, ["name",  "productName", "price", "quantity","fees","total", "paid"],exportName+" - Par adherent");
			return null;
		}else{
			return orders;
		}
		
	}
	
	/**
	 * Get the orders (varying orders) of a user for a multidistrib ( distribs with same day + same place )
	 * 
	 * @param	distribKey "$date|$placeId"
	 */
	public static function getUserOrdersByMultiDistrib(distribKey:String, user:db.User,group:db.Amap):Array<db.UserContract>{	
		var contracts = db.Contract.getActiveContracts(group);
		for ( c in Lambda.array(contracts)){
			if (c.type == db.Contract.TYPE_CONSTORDERS){
				contracts.remove(c); //only varying orders
			}
		}
		
		var cids = Lambda.map(contracts, function(x) return x.id);
		var start = Date.fromString(distribKey.split("|")[0] + " 00:00:00");
		var end = Date.fromString(distribKey.split("|")[0] + " 23:59:00");
		var ds = db.Distribution.manager.search($date > start && $date < end && ($contractId in cids), false);
		var out = [];
		for (d in ds) {
			out = out.concat(Lambda.array(user.getOrdersFromDistrib(d)));
		}
		
		return out;
		
	}
	
	/**
	 * Confirms an order
	 * @param	order
	 */
	public static function confirmSessionOrder(order:OrderInSession){
		
		
		var orders = [];
		var user = db.User.manager.get(order.userId);
		for (o in order.products){
			
			o.product = db.Product.manager.get(o.productId);
			orders.push( db.UserContract.make(user, o.quantity, o.product, o.distributionId) );
			
		}
		
		App.current.event(MakeOrder(orders));
		App.current.session.data.order = null;	
		
		return orders;
	}
	
	
	public static function getTotalPrice(orders:Iterable<UserOrder>){
		var t = 0.0;
		for ( o in orders) t += o.total;
		return t;
		
	}
}
