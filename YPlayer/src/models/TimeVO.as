package models
{
	import com.pamakids.models.BaseVO;

	public class TimeVO extends BaseVO
	{
		public function TimeVO()
		{
		}

		public var name:String;
		public var begin:Date;
		public var end:Date;
		public var songs:Array;
	}
}

