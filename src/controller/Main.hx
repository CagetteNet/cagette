package controller;
import db.Distribution;
import db.UserContract;
import haxe.Json;
import haxe.web.Dispatch;
import sugoi.form.elements.StringInput;
import sugoi.tools.ResultsBrowser;
import Common;
import tools.ArrayTool;

class Main extends Controller {
	
	
	/**
	 * public pages 
	 */
	function doGroup(d:haxe.web.Dispatch){
		d.dispatch(new controller.Group());
	}

	@tpl("home.mtt")
	function doDefault() {
		view.category = 'home';
		
		var group = app.getCurrentGroup();		
		if ( app.user!=null && group == null) {			
			throw Redirect("/user/choose");
		}else if (app.user == null && (group==null || group.regOption!=db.Amap.RegOption.Open) ) {
			throw Redirect("/user/login");
		}

		view.amap = group;
		
		//contrats ouverts à la commande
		var openContracts = Lambda.filter(group.getActiveContracts(), function(c) return c.isUserOrderAvailable());
		view.openContracts = openContracts;
		
		//s'inscrire a une distribution
		view.contractsWithDistributors = app.user==null ? [] : Lambda.filter(app.user.getContracts(), function(c) return c.distributorNum > 0);
		
		//freshly created group
		view.newGroup = app.session.data.newGroup == true;
	
		var distribs = getNextMultiDeliveries(group);
		
		//fix bug du sorting (les distribs du jour se mettent en bas)
		var out = [];
		for (x in distribs) out.push(x);
		out.sort(function(a, b) {
			return Std.int(a.startDate.getTime()/1000) - Std.int(b.startDate.getTime()/1000);
		});
		
		view.distribs = out;
		
		//event for additionnal blocks on home page
		var e = Blocks([], "home");
		app.event(e);
		view.blocks = e.getParameters()[0];
	}
	
	/**
	 * Get next multi-deliveries ( deliveries including more than one vendors )
	 */
	function getNextMultiDeliveries(group:db.Amap){
		
		var out = new Map < String, {
			place:db.Place, //common delivery place
			startDate:Date, //global delivery start
			endDate:Date,	//global delivery stop
			orderStartDate:Date, //global orders opening date
			orderEndDate:Date,//global orders closing date
			active:Bool,
			products:Array<ProductInfo>, //available products ( if no order )
			myOrders:Array<{distrib:Distribution,orders:Array<db.UserContract>}>	//my orders
			
		}>();
		
		var now = Date.now();
		var now9 = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
	
		var contracts = db.Contract.getActiveContracts(group);
		var cids = Lambda.map(contracts, function(p) return p.id);
		
		//var pids = Lambda.map(db.Product.manager.search($contractId in cids,false), function(x) return x.id);
		//var out =  UserContract.manager.search(($userId == id || $userId2 == id) && $productId in pids, lock);	
		
		//available deliveries + next deliveries in less than a month		
		var distribs = db.Distribution.manager.search(($contractId in cids) && ($date >= now9) , { orderBy:date }, false);
		var inOneMonth = DateTools.delta(now9, 1000.0 * 60 * 60 * 24 * 30);
		
		for (d in distribs) {			
			
			//we had the distribution key ( place+date ) and the contract type in order to separate constant and varying contracts
			var key = d.getKey() + "|" + d.contract.type;
			var o = out.get(key);
			if (o == null) o = {place:d.place, startDate:d.date, active:null, endDate:d.end, products:[], myOrders:[], orderStartDate:null,orderEndDate:null};
			
			//user orders
			var orders = [];
			if(app.user!=null) orders = d.contract.getUserOrders(app.user,d);
			if (orders.length > 0){
				o.myOrders.push({distrib:d,orders:Lambda.array(orders)});
			}else{
				//no "order block" if no shop mode	
				if (!group.hasShopMode() ) {		
					continue;		
				}		

				//if its a constant order contract, skip this delivery		
				if (d.contract.type == db.Contract.TYPE_CONSTORDERS){		
					continue;		
				}
				
				//products preview if no orders
				for ( p in d.contract.getProductsPreview(9)){
					o.products.push( p.infos(null,false) );	
				}	
			}
			
			if (d.contract.type == db.Contract.TYPE_VARORDER){
				
				//old distribs may have an empty orderStartDate
				if (d.orderStartDate == null) {
					continue;
				}
				
				//if order opening is more far than 1 month, skip it
				if (d.orderStartDate.getTime() > inOneMonth.getTime() ){
					continue;
				}
				
				//display closest opening date
				if (o.orderStartDate == null){
					o.orderStartDate = d.orderStartDate;
				}else if (o.orderStartDate.getTime() > d.orderStartDate.getTime()){
					o.orderStartDate = d.orderStartDate;
				}
				
				//display farest closing date
				if (o.orderEndDate == null){
					o.orderEndDate = d.orderEndDate;
				}else if (o.orderEndDate.getTime() < d.orderEndDate.getTime()){
					o.orderEndDate = d.orderEndDate;
				}
				
				out.set(key, o);	
				
			}else{
				//in constant orders, add block only if there is an order
				if(o.myOrders.length>0) out.set(key, o);
				
			}
			
			
		}
		
		//shuffle and limit product lists		
		for ( o in out){
			o.products = thx.Arrays.shuffle(o.products);			
			o.products = o.products.slice(0, 9);
		}
		
		//decide if active or not
		for( o in out){
			
			if (o.orderStartDate == null) continue; //constant orders
			
			if (now.getTime() >= o.orderStartDate.getTime()  && now.getTime() <= o.orderEndDate.getTime() ){
				//order currently open
				o.active = true;
				
			}else {
				o.active = false;
				
			}
		}	
		
		
		return Lambda.array(out);
	}
	
	
	
	//login and stuff
	function doUser(d:Dispatch) {
		d.dispatch(new controller.User());
	}
	
	function doCron(d:Dispatch) {
		d.dispatch(new controller.Cron());
	}
	
	function doApi(d:Dispatch) {
		try {
			d.dispatch(new controller.Api());
		}catch (e:tink.core.Error){
			sugoi.Web.setReturnCode(e.code);
			Sys.print(Json.stringify( {error:{code:e.code,message:e.message}} ));
			
		}catch (e:Dynamic){
			sugoi.Web.setReturnCode(500);
			var stack = "";
			if ( App.config.DEBUG ) stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
			Sys.print(Json.stringify( {error:{message : Std.string(e), stack:stack}} ));
		}
		
	}
	
	@tpl("cssDemo.mtt")
	function doCssdemo() {
		
	}
	
	@tpl("form.mtt")
	function doInstall(d:Dispatch) {
		d.dispatch(new controller.Install());
	}
	

	function doP(d:Dispatch) {
		
		/*
		 * Invalid array access
Stack (ADMIN|DEBUG)

Called from C:\HaxeToolkit\haxe\std/haxe/web/Dispatch.hx line 463
Called from controller/Main.hx line 117
		 * 
		var plugin = d.parts.shift();
		for ( p in App.plugins) {
			var n = Type.getClassName(Type.getClass(p)).toLowerCase();
			n = n.split(".").pop();
			if (plugin == n) {
				d.dispatch( p.getController() );
				return;
			}
		}
		
		throw Error("/","Plugin '"+plugin+"' introuvable.");
		*/
		
		d.dispatch(new controller.Plugin());
	}
	

	@logged
	function doMember(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Member());
	}
	
	@logged
	function doStats(d:Dispatch) {
		view.category = 'stats';
		d.dispatch(new Stats());
	}
	
	@logged
	function doAccount(d:Dispatch) {
		view.category = 'account';
		d.dispatch(new controller.Account());
	}

	@logged
	function doVendor(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Vendor());
	}
	
	@logged
	function doPlace(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Place());
	}
	
	@logged
	function doTransaction(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Transaction());
	}
	
	@logged
	function doDistribution(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Distribution());
	}
	
	@logged
	function doMembership(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Membership());
	}
	
	function doShop(d:Dispatch) {
		view.category = 'shop';
		d.dispatch(new controller.Shop());
	}

	@tpl('shop/default2.mtt')
	function doShop2(place:db.Place, date:String) {
		view.category = 'shop';
		view.place = place;
		view.date = date;
	}
	
	@logged
	function doProduct(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Product());
	}
	
	@logged
	function doAmap(d:Dispatch) {
		view.category = 'amap';
		d.dispatch(new controller.Amap());
	}
	
	@logged
	function doContract(d:Dispatch) {
		view.category = 'contract';
		d.dispatch(new Contract());
	}
	
	@logged
	function doContractAdmin(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new ContractAdmin());
	}
	
	@logged
	function doMessages(d:Dispatch) {
		view.category = 'messages';
		d.dispatch(new Messages());
	}
	
	@logged
	function doAmapadmin(d:Dispatch) {
		view.category = 'amapadmin';
		d.dispatch(new AmapAdmin());
	}
	
	@logged
	function doValidate(date:Date, place:db.Place, user:db.User, d:haxe.web.Dispatch){
		
		var v = new controller.Validate();
		v.date = date;
		v.place = place;
		v.user = user;		
		d.dispatch(v);
	}
	
	@admin
	function doAdmin(d:Dispatch) {
		d.dispatch(new controller.admin.Admin());
	}
	
	
	
	
	@admin
	function doDb(d:Dispatch) {
		d.parts = []; //disable haxe.web.Dispatch
		sys.db.Admin.handler();
	}
	
	
}
