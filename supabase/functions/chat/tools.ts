import { Type } from "npm:@google/genai";

export function buildToolDeclarations() {
  return [{
    functionDeclarations: [
      {
        name: "search_products",
        description:
          "搜尋商店真實上架商品。需要具體單品時呼叫；回傳的 id 之後用於 respond。除 query 與 category_name 外，其餘屬性參數皆為選填，只有當使用者明確提到該條件時才填，否則留空以免過度篩選而找不到商品。",
        parameters: {
          type: Type.OBJECT,
          properties: {
            query: {
              type: Type.STRING,
              description:
                "只比對『商品名稱』與『店家/品牌名稱』。多個詞以空白分隔，且每個詞都必須出現在商品名稱中（AND），所以請用少量、可能出現在名稱裡的字（如『襯衫』『洋裝』或品牌名）。顏色、材質、風格、季節、分類請勿放這裡——改用對應參數。",
            },
            category_name: { type: Type.STRING, description: "商品分類名稱，需與分類清單一致" },
            gender: {
              type: Type.STRING,
              description:
                "選填。依商品適用性別篩選，只能用：male, female, unisex。可參考使用者資訊自行決定是否使用。",
            },
            materials: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "選填。材質關鍵字（自由文字，子字串比對），如 棉、麻、羊毛、聚酯纖維。",
            },
            styles: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description:
                "選填。風格，只能用這些固定英文值：japanese, korean, western, british, chinese, minimalist, casual, sporty, lazy, streetwear, business, preppy, functional, vintage, artsy, literary, elegant, mature, neutral, spicy, sweet。",
            },
            seasons: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "選填。季節，只能用：spring, summer, autumn, winter。",
            },
            fits: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "選填。版型，只能用：合身, 常規, 大尺碼, oversize。",
            },
            elasticities: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "選填。彈性，只能用：none, low, medium, high。",
            },
            thicknesses: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "選填。厚度，只能用：low, medium, high。",
            },
            channels: {
              type: Type.ARRAY,
              items: { type: Type.STRING },
              description: "選填。購物管道，只能用：physical（實體店面）, online（線上）。",
            },
            min_price: { type: Type.NUMBER, description: "選填。價格下限。" },
            max_price: { type: Type.NUMBER, description: "選填。價格上限。" },
          },
        },
      },
      {
        name: "search_wardrobe",
        description: "搜尋使用者衣櫃既有衣物；想用既有單品搭配時優先呼叫。",
        parameters: {
          type: Type.OBJECT,
          properties: {
            category: {
              type: Type.STRING,
              description: "top / bottoms / outerwear / sets / others",
            },
            tags: { type: Type.ARRAY, items: { type: Type.STRING } },
          },
        },
      },
      {
        name: "respond",
        description:
          "送出最終回覆。blocks 是有序的內容區塊，依序顯示給使用者：text（一段話）、product（商店商品，用 search_products 回傳的 id）、wardrobe（衣櫃單品，用 search_wardrobe 回傳的 id）。一個 product/wardrobe 區塊只放一件；要多件就放多個。整套穿搭就用「text 描述某部位 → 該部位的 product/wardrobe」交錯表達。",
        parameters: {
          type: Type.OBJECT,
          properties: {
            blocks: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  type: { type: Type.STRING, description: "text、product 或 wardrobe" },
                  text: { type: Type.STRING, description: "type=text 時的文字內容" },
                  id: {
                    type: Type.STRING,
                    description:
                      "type=product 時為 search_products 回傳的商品 id；type=wardrobe 時為 search_wardrobe 回傳的衣櫃單品 id",
                  },
                },
                required: ["type"],
              },
            },
          },
          required: ["blocks"],
        },
      },
    ],
  }];
}
