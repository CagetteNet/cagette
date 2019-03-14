package db;
import sys.db.Object;
import sys.db.Types;
import Common;

/**
 * Vendor (farmer/producer/vendor)
 */
class Vendor extends Object
{
	public var id : SId;
	public var name : SString<128>;
	
	public var legalStatus : SNull<SEnum<LegalStatus>>;
	@hideInForms public var profession : SNull<SInt>;

	public var email : STinyText;
	public var phone:SNull<SString<19>>;
		
	public var address1:SNull<SString<64>>;
	public var address2:SNull<SString<64>>;
	public var zipCode:SString<32>;
	public var city:SString<25>;
	public var country:SNull<SString<64>>;
	
	public var desc : SNull<SText>;
	
	public var linkText:SNull<SString<256>>;
	public var linkUrl:SNull<SString<256>>;
	
	@hideInForms @:relation(imageId) 	public var image : SNull<sugoi.db.File>;
	@hideInForms @:relation(userId) 	public var user : SNull<db.User>; //owner of this vendor
	
	@hideInForms @:relation(amapId) public var amap : SNull<Amap>;//DEPRECATED
	@hideInForms public var status : SNull<SString<32>>; //temporaire , pour le dédoublonnage

	public static var PROFESSIONS:Array<{id:Int,name:String}>;
	
	
	public function new() 
	{
		super();
		legalStatus = Business;
		try{
			var t = sugoi.i18n.Locale.texts;
			name = t._("Supplier");
		}catch(e:Dynamic){}
	}
	
	override function toString() {
		return name;
	}

	public function getContracts(){
		return db.Contract.manager.search($vendor == this,{orderBy:-startDate}, false);
	}

	public function getActiveContracts(){
		var now = Date.now();
		return db.Contract.manager.search($vendor == this && $startDate < now && $endDate > now ,{orderBy:-startDate}, false);
	}

	public function infos():VendorInfos{
		var out = {
			id 		: id,
			name 	: name,
			desc 	: desc,
			image 	: App.current.view.file(image),
			profession : null,
			//images 	: null
			zipCode : zipCode,
			city 	: city,
			linkText	:linkText,
			linkUrl		:linkUrl,			
		};

		if(this.profession!=null){
			out.profession = Lambda.find(getVendorProfessions(),function(x) return x.id==this.profession).name;
		}

		return out;
	}

	public function getGroups():Array<db.Amap>{
		var contracts = getActiveContracts();
		var groups = Lambda.map(contracts,function(c) return c.amap);
		return tools.ObjectListTool.deduplicate(groups);
	}

	public static function get(email:String,status:String){
		return manager.select($email==email && $status==status,false);
	}

	public static function getForm(vendor:db.Vendor){
		var t = sugoi.i18n.Locale.texts;
		var form = sugoi.form.Form.fromSpod(vendor);
		
		//country
		form.removeElementByName("country");
		form.addElement(new sugoi.form.elements.StringSelect('country',t._("Country"),db.Place.getCountries(),vendor.country,true));
		
		//profession
		form.addElement(new sugoi.form.elements.IntSelect('profession',t._("Profession"),sugoi.form.ListData.fromSpod(getVendorProfessions()),vendor.profession,false),3);
		
		return form;
	}
	
	public static function getLabels(){
		var t = sugoi.i18n.Locale.texts;
		return [
			"name" 				=> t._("Supplier name"),
			"desc" 				=> t._("Description"),
			"email" 			=> t._("Email"),
			"phone" 			=> t._("Phone"),
			"address1" 			=> t._("Address 1"),
			"address2" 			=> t._("Address 2"),
			"zipCode" 			=> t._("Zip code"),
			"city" 				=> t._("City"),			
			"linkText" 			=> t._("Link text"),			
			"linkUrl" 			=> t._("Link URL"),			
		];
	}

	/**
		Loads vendors professions from json
	**/
	public static function getVendorProfessions():Array<{id:Int,name:String}>{
		if( PROFESSIONS!=null ) return PROFESSIONS;
		var filePath = sugoi.Web.getCwd()+"../data/vendorProfessions.json";
		var json = haxe.Json.parse(sys.io.File.getContent(filePath));
		PROFESSIONS = json.professions;
		return json.professions;
	}
	
}