require_relative 'spec_helper'
require 'redstone_bot/item_types'
require 'redstone_bot/entities'

describe RedstoneBot::ItemType do
  it "can flexibly figure out what block type you want" do
    glass = RedstoneBot::ItemType::Glass
    described_class.from("glass").should == glass
    described_class.from("20").should == glass
    described_class.from("0x14").should == glass
    described_class.from(20).should == glass
    described_class.from(nil).should == nil
    described_class.from("nil").should == nil
    described_class.from("diamond").should == RedstoneBot::ItemType::Diamond
    described_class.from("diamond ore").should == RedstoneBot::ItemType::DiamondOre
  end
  
  it "has items also" do
    described_class.from(256).should == RedstoneBot::ItemType::IronShovel
  end
  
  it "avoids ambiguous names" do
    names = described_class.instance_variable_get(:@types_by_string).keys
    names.size.should > 100
    names.each do |name|
      if name =~ /(.+)Item\Z/ || name =~ /(.+)Block\Z/
        names.should not_has_key $1
      end
    end
  end
  
  it "has a nice matcher" do
    s = double("something")
    s.stub(:item_type) { RedstoneBot::ItemType::IronShovel}
    RedstoneBot::ItemType::IronShovel.should === s
    RedstoneBot::ItemType::IronShovel.should === RedstoneBot::Item.new(44, RedstoneBot::ItemType::IronShovel, 1, nil)
    RedstoneBot::ItemType::IronShovel.should === RedstoneBot::ItemType::IronShovel
  end
end