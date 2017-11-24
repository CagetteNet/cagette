/**
 * Shared entities between server and client
 */

@:keep
typedef OrderSimple = {
	products: Array<{
		product:ProductInfo,
		quantity:Int
	}>,
	total:Float
}

@:keep
typedef OrderInSession = {
	products:Array <{
		productId:Int,
		quantity:Float,
		#if !js
		?product:db.Product,
		?distributionId:Int,
		#end
	} > ,
	?userId:Int,
	total:Float, 	//price to pay
	?paymentOp:Int, //payment operation ID
}

@:keep
typedef ProductInfo = {
	id : Int,
	name : String,
	?ref : String,
	type : ProductType,
	image : Null<String>,
	contractId : Int,
	price : Float,
	vat : Float,
	vatValue : Float,			//montant de la TVA inclue dans le prix
	contractTax : Float, 		//pourcentage de commission défini dans le contrat
	contractTaxName : String,	//label pour la commission : ex: "frais divers"
	desc : String,
	categories : Array<Int>,	//used in old shop
	subcategories : Array<Int>,  //used in new shop
	orderable : Bool,			//can be currently ordered
	stock: Null<Float>,			//available stock
	hasFloatQt : Bool,
	?qt:Float,
	?unitType:UnitType,
	organic:Bool,
	#if (js && !test)
	element:js.JQuery,
	#end
}

@:keep
typedef ProductWithQuantity = {
	product: ProductInfo,
	quantity: Int
}

enum UnitType{
	Piece;
	Kilogram;
	Gram;
	Litre;
	Centilitre;
}

@:keep
enum ProductType {
	CTVegetable;
	CTCheese;
	CTChicken;
	CTUnknown;
	CTWine;
	CTMeat;
	CTEggs;
	CTHoney;
	CTFish;
	CTJuice;
	CTApple;
	CTBread;
	CTYahourt;
	
}

typedef CategoryInfo = {
	id:Int,
	name:String,
	?subcategories:Array<CategoryInfo>
}

/**
 * datas used with the "tagger" ajax class
 */
@:keep
typedef TaggerInfos = {
	products:Array<{product:ProductInfo,categories:Array<Int>}>,//tagged products
	categories : Array<{id:Int,categoryGroupName:String,color:String,tags:Array<{id:Int,name:String}>}>, //groupe de categories + tags
}

/**
 * Links in navbars for plugins
 */
typedef Link = {
	id:String,
	link:String,
	name:String,
	?icon:String,
}

typedef Block = {
	id:String,
	title:String,
	?icon:String,
	html:String
}

typedef UserOrder = {
	id:Int,
	userId:Int,
	userName:String,
	?userEmail : String,
	
	?userId2:Int,
	?userName2:String,
	?userEmail2:String,
	
	productId:Int,
	productRef:String,
	productName:String,
	productPrice:Float,
	productImage:String,
	
	quantity:Float,
	subTotal:Float,
	fees:Float,
	percentageName:String,
	percentageValue:Float,
	total:Float,
	paid:Bool,
	canModify:Bool,
	
	contractId:Int,
	contractName:String,
}

typedef PlaceInfos = {
	name:String,
	address1:String,
	address2:String,
	zipCode:String,
	city:String,
	latitude:Float,
	longitude:Float
}

enum OrderFlags {
	InvertSharedOrder;
	//Paid;
}

/**
	Event enum used for plugins.
	
	As in most CMS event systems, 
	the events (or "triggers") can be catched by plugins 
	to perform an action or modifiy data carried by the event.
	
**/
	
typedef OrderByProduct = {quantity:Float,pid:Int,pname:String,ref:String,price:Float,total:Float};
typedef OrderByEndDate = {
	date: String,
	contracts: Array<String>
};


enum Event {

	Page(uri:String);							//a page is displayed
	Nav(nav:Array<Link>, name:String, ?id:Int);	//a navigation is displayed, optionnal object id if needed
	Blocks(blocks:Array<Block>, name:String);	//HTML blocks that can be displayed on a page
	
	#if sys
	SendEmail(message : sugoi.mail.Mail);		//an email is sent
	NewMember(user:db.User,group:db.Amap);		//a new member is added to a group
	NewGroup(group:db.Amap, author:db.User);	//a new group is created
	
	//Distributions
	PreNewDistrib(contract:db.Contract);		//when displaying the insert distribution form
	NewDistrib(distrib:db.Distribution);		//when a new distrinbution is created
	PreEditDistrib(distrib:db.Distribution);
	EditDistrib(distrib:db.Distribution);
	DeleteDistrib(distrib:db.Distribution);
	PreNewDistribCycle(cycle:db.DistributionCycle);	
	NewDistribCycle(cycle:db.DistributionCycle);
	
	//Products
	PreNewProduct(contract:db.Contract);	//when displaying the insert distribution form
	NewProduct(product:db.Product);			//when a new distrinbution is created
	PreEditProduct(product:db.Product);
	EditProduct(product:db.Product);
	DeleteProduct(product:db.Product);
	BatchEnableProducts(data:{pids:Array<Int>,enable:Bool});
	
	//Contracts
	DeleteContract(contract:db.Contract);
	
	//crons
	DailyCron;
	HourlyCron;
	MinutelyCron;
	
	//orders
	MakeOrder(orders:Array<db.UserContract>); 
	StockMove(order:{product:db.Product, move:Float}); //when a stock is modified
	
	//payments
	GetPaymentTypes(data:{types:Array<payment.Payment>});
	NewOperation(op:db.Operation);
	
	#end
	
}


/*
 * Product Taxonomy structure
 */ 
typedef TxpDictionnary = {
	products:Map<Int,{id:Int,name:String,category:Int,subCategory:Int}>,
	categories:Map<Int,{id:Int,name:String}>,
	subCategories:Map<Int,{id:Int,name:String}>,
	
}


/* 
 * Tutorials
 */
enum TutoAction {
	TAPage(uri:String);
	TANext;
	
}
enum TutoPlacement {
	TPTop;
	TPBottom;
	TPLeft;
	TPRight;
}

class TutoDatas {

	public static var TUTOS;
	
	#if js
	//async 
	public static function get(tuto:String, callback:Dynamic->Void){
		#if !test
		sugoi.i18n.Locale.init(App.instance.LANG, function(t:sugoi.i18n.GetText){			
			App.instance.t = t;
			init(t);
			var tuto = TUTOS.get(tuto);
			callback(tuto);			
		});
		#end
	}
	#else
	//sync 
	public static function get(tuto:String):{name:String, steps:Array<{element:String,text:String,action:TutoAction,placement:TutoPlacement}>}
	{
		sugoi.i18n.Locale.init(App.current.getLang());
		init(sugoi.i18n.Locale.texts);
		return TUTOS.get(tuto);
	}
	#end
	
	static function init(t:sugoi.i18n.GetText){
			
		TUTOS = [
			"intro" => {
				name:t._("Guided tour for the coordinator"),
				steps:[
					{
						element:null,
						text:t._("<p>In order to better discover Cagette.net, we propose to do a guided tour of the user interface of the software. <br/> You will then have a global overview on the different tools that are available to you.</p><p>You will be able to stop and start again this tutorial whenever you want.</p>"),
						action: TANext,
						placement : null
					},
					{
						element:"ul.nav.navbar-left",
						text:t._( "This part of the navigation bar is visible by all members.</br>It allows to access to the three main pages:	<ul><li> The <b>home page</b> which displays orders and the delivery planning.</li><li> On the <b>My account</b> page, you can update your personal information and check your orders history</li><li> On the <b>My group</b> page,  you can see all farmers and coordinators of the group</ul>"),
						action: TANext,
						placement : TPBottom
					},
					{
						element:"ul.nav.navbar-right",
						text:t._("This part is <b>for coordinators only.</b>Here you will be able to manage the register of members, orders,  products, etc.<br/><p>Now click on the <b>Members</b> section</p>"),
						action: TAPage("/member"),
						placement : TPBottom

					},{
						element:".article .table td:first",
						text:t._("The purpose of this section is to administrate the list of your members.<br/>Every time that you register a new membrer, an account will be created for him/her. Now the member can join you at Cagette.net and order or consult the planning of the deliveries.<p>Now click on a <b>member</b> in the list</p>"),
						action: TAPage("/member/view/*"),
						placement : TPRight
					},{
						element:".article:first",
						text:t._("This is the page of a member. Here you can : <ul><li>see and change their contact details</li><li>manage the membership fee of your group</li><li>see a summary of their orders</li></ul>"),
						action: TANext,
						placement : TPRight
					},{
						element:"ul.nav #contractadmin",
						text:t._("Now let's have a look at the <b>contracts</b> section which is very important for coordinators."),
						action: TAPage("/contractAdmin"),
						placement : TPBottom
					},{
						element:"#contracts",
						text:t._("Here you find the list of <b>contracts</b>.They inculde a start date, a end date, and represent your relationship with a farmer. <br/><p>Here you can manage :<ul><li>the list of products of this farmer</li><li>the orders of members for this farmer</li><li>and plan the delivery schedule</li></ul></p>"),
						action: TANext,
						placement : TPBottom

					},{
					element:"#places",
					   text:t._("Here you can manage the list of <b>delivery places</b>.<br/>Don't forget to key-in the complete address as a map will be displayed based on this address"),
					   action: TANext,
					   placement : TPTop

				   },{
					   element:"#contracts table .btn:first",
					   text:t._("Let's look closer at how to manage a contract. <b>Click on this button</b>"),
					   action: TAPage("/contractAdmin/view/*"),
					   placement : TPBottom

				   },{
					   element:".table.table-bordered:first",
					   text:t._("Here is a summary of the contract.<br/>There are two types of contracts:<ul><li>Constant contracts: the member commits on buying the same products during the whole duration of the contract</li><li>Variable contracts: the member can choose what he buys for each delivery.</li></ul>"),
					   action: TANext,
					   placement : TPRight

				   },{
					   element:"#subnav #products",
					   text:t._("Let's see now the page <b>Products</b>"),
					   action : TAPage("/contractAdmin/products/*"),
					   placement:TPRight
				   },{
					   element:".article .table",
					   text:t._("On this page, you can manage the list of products offered by this supplier.<br/>Define at least the name and the price of products. It is also possible to add a description and a picture."),
					   action: TANext,
					   placement : TPTop

				   },{
					   element:"#subnav #deliveries",
					   text:t._("Let's see the <b>deliveries</b> page"),
					   action : TAPage("/contractAdmin/distributions/*"),
					   placement:TPRight
				   },{
					   element:".article .table",
					   text:t._("Here we can manage the list of deliveries for this supplier.<br/>In the software, a delivery has a date, a start time, and an end time. The location of the delivery must also be defined, by using the list that we have already seen."),
					   action: TANext,
					   placement : TPLeft

				   },{
					   element:"#subnav #orders",
					   text:t._("Let's see now the <b>Orders</b> page"),
					   action : TAPage("/contractAdmin/orders/*"), //can fail if the contract is variable because the uri is different
					   placement:TPRight
				   },{
					   element:".article .table",
					   text:t._("Here we can manage the list of orders for this supplier.<br/>If you choose to \"open orders\" to members, they will be able to make their orders online themselves.<br/>This page will centralize automatically the orders for this supplier.  Otherwise, as a coordinator, you will be able to enter orders on behalf of a member."),
					   action: TANext,
					   placement : TPLeft

				   },{
					   element:"ul.nav #messages",
					   text:t._("<p>We have seen the main features related to contracts.</p><p>Let's see the <b>messaging</b> section.</p>"),
					   action: TAPage("/messages"),
					   placement : TPBottom

				   },{
					   element:null,
					   text:t._("<p>The messaging section allows you to send e-mails to different lists of members. It is not necessary anymore to maintain a lot of lists of e-mails depending on contracts, as all these lists are automatically generated.</p>  <p>E-mails are sent with your e-mail address as sender, so you will receive answers in your own mailbox.</p>"),
					   action: TANext,
					   placement : null

				   },{
					   element:"ul.nav #amapadmin",
					   text:t._("Click here now on this page"),
					   action : TAPage("/amapadmin"),
					   placement : TPBottom,
				   },{
					   element:"#subnav",
					   text:t._("<p>In this last page, you can configure everything that is related to your group.</p><p>The page <b>Access rights</b> is important as it is where you can define other coordinators among members. They will then be able to manage one or many contracts, send emails, etc.</p>"),
					   action:TANext,
					   placement : TPBottom
				   },{
					   element:"#footer",
					   text:t._("<p>This is the last step of this tutorial. I hope that it gave you a good overview of this software.<br/>To go further, do not hesitate to look at the <b>documentation</b>. The link is always available at the bottom of the screen.</p>"),
					   action:TANext,
					   placement : TPBottom
				   }
			   ]
		   },
		];
		
	}
	
	

}

/**
 * Order Reports
 */
enum OrdersReportGroupOption{
	ByMember;
	ByProduct;
}

enum OrdersReportFormatOption{
	Table;
	Csv;
	PrintableList; //list de distrib ?
}


//Report Options : should be usable in an URL, an API call...
typedef OrdersReportOptions = {
	//time scope
	startDate:Date,
	endDate:Date,
	
	//formatting
	?groupBy:OrdersReportGroupOption,			//group order by...	
	?format:OrdersReportFormatOption,			//table , csv ?
	
	//filters :
	?groups:Array<Int>,
	?contracts:Array<Int>,			//which contracts
	?distributions:Array<Int>,
}
