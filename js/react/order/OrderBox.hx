package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.router.Link;

typedef OrderBoxState = {orders:Array<UserOrder>,error:String};
typedef OrderBoxProps = {
	userId:Int,
	distributionId:Int,
	contractId:Int,
	contractType:Int,
	date:String,
	place:String,
	userName:String,
	onSubmit:Void->Void,
	currency:String,
	hasPayments:Bool
};

/**
 * A box to edit/add orders of a member
 * @author fbarbut
 */
class OrderBox extends react.ReactComponentOfPropsAndState<OrderBoxProps,OrderBoxState>
{

	public function new(props) 
	{
		super(props);	
		state = { orders : [], error : null };
	}
	
	override function componentDidMount()
	{
		if(App.SAVED_ORDER_STATE!=null) {
			//get state from saved state
			trace("restore previous state");
			setState(App.SAVED_ORDER_STATE);
			return;
		}

		//request api avec user + distrib
		HttpUtil.fetch("/api/order/get/"+props.userId, GET, {distributionId:props.distributionId,contractId:props.contractId}, PLAIN_TEXT)
		.then(function(data:String) {

			var data : {orders:Array<UserOrder>} = tink.Json.parse(data);
			/*for( o in orders){
				//convert ints to enums, enums have been lost in json serialization
				o.productUnit = Type.createEnumIndex(UnitType, cast o.productUnit );	
			}*/
			setState({orders:data.orders, error:null});
		}).catchError(function(error) {
			trace("PROMISE ERROR :" + Std.string(error));
			setState(cast {error:error.message});
		});
	}
	
	override public function render(){
		
		var renderOrders = this.state.orders.map(function(o) return jsx('<$Order key=${o.id} order="$o" onUpdate=$onUpdate parentBox=${this} />') );
		
		return jsx('
			<div>
				<h3>Commandes de ${props.userName}</h3>
				<p>
					Pour la livraison du <b>${props.date}</b> à <b>${props.place}</b>			
				</p>
				<$Error error="${state.error}" />
				<hr/>
				${renderOrders}	
				<div>
					<a onClick=${onClick} className="btn btn-primary">
						<span className="glyphicon glyphicon-chevron-right"></span> Valider
					</a>
					&nbsp;
					<$Link className="btn btn-default" to="/insert"><span className="glyphicon glyphicon-plus-sign"></span> Nouvelle commande</$Link>
				</div>
			</div>			
		');
	}
	
	/**
	 * called when an order is updated
	 */
	function onUpdate(data:UserOrder){
		trace("ON UPDATE : " + data);
		for ( o in state.orders){
			if (o.id == data.id) {
				o.quantity = data.quantity;
				o.paid = data.paid;
			}
		}
		/*
		//save state outside component
		trace("save state");
		App.SAVED_ORDER_STATE = this.state;*/
	}
	
	/**
	 * submit updated orders to the API
	 */
	function onClick(_){
		
		var data = new Array<{id:Int,productId:Int,qt:Float,paid:Bool}>();
		for ( o in state.orders) data.push({id:o.id, productId : o.productId, qt: o.quantity, paid : o.paid});
		trace("CLICK : " + data);
		
		var req = {
			orders:haxe.Json.stringify(data),
			distributionId : props.distributionId,
			contractId : props.contractId
		};
		
		var p = HttpUtil.fetch("/api/order/update/"+props.userId, POST, req,JSON);
		p.then(function(data:Dynamic) {

			//WOOT
			trace("OK");
			if (props.onSubmit != null) props.onSubmit();

		}).catchError(function(data) {
			trace("PROMISE ERROR", data);
			this.state.error = data.error.message;
			setState(this.state);
		});
		
	}

	
	
}