package models
{

	[Bindable]
	public class MenuVO
	{
		public static const BACKGROUND_MUSIC:int=1;
		public static const DM:int=2;
		public static const DM_LOCAL:int=3;

		public function MenuVO()
		{
		}

		public var name:String;
		public var list:Array;
		public var dm_list:Array;
		public var end_date:Date;
		public var _id:String;
		public var updated_at:Date;
		public var begin_date:Date;
		public var quality:Number;
		public var tags:Array;
		public var type:int;
		public var selected:Boolean;
	}
}

