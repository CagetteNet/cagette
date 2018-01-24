package controller;
import db.UserContract;
import sugoi.form.Form;
import haxe.crypto.Md5;

class Amap extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("amap/default.mtt")
	function doDefault() {
		var contracts = db.Contract.getActiveContracts(app.user.amap, true, false);
		for ( c in Lambda.array(contracts).copy()) {
			if (c.endDate.getTime() < Date.now().getTime() ) contracts.remove(c);
		}
		view.contracts = contracts;
	}
	
	
	@tpl("form.mtt")
	function doEdit() {
		
		if (!app.user.isAmapManager()) throw t._("You don't have access to this section");
		
		var group = app.user.amap;
		
		var form = Form.fromSpod(group);

		//remove checkboxes GroupType that are not activated in the configuration
		var e = form.getElement("groupType");
		var radioG = cast(e, sugoi.form.elements.Enum);
		var groups = App.config.get("group_types").split(";");
		var groups2 = new Array();
		for(group in groups)
		{
			groups2.push(Std.parseInt(group));
		}
		radioG.setActivatedValues(groups2);




		if (form.checkToken()) {
			form.toSpod(group);
			
			if (group.extUrl != null){
				if ( group.extUrl.indexOf("http://") ==-1 &&  group.extUrl.indexOf("https://") ==-1 ){
					group.extUrl = "http://" + group.extUrl;
				}
			}
			
			group.update();
			throw Ok("/amapadmin", t._("The group has been updated."));
		}
		
		view.form = form;
	}
	
}