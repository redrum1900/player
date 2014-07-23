package models
{
	import com.pamakids.models.BaseVO;

	public class InsertVO extends BaseVO
	{
		public function InsertVO()
		{
			super();
		}

		public var url:String;
		public var name:String;
		public var playTime:Date;
		public var repeat:int;
		public var interval:int;
		public var duration:Number;
		public var type:int;
		public var size:Number;
	}
}

