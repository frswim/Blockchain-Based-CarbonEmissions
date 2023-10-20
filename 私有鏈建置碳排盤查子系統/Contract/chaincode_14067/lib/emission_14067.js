/* Copyright IBM Corp. All Rights Reserved.
*
* SPDX-License-Identifier: Apache-2.0
*/

'use strict';

// Deterministic JSON.stringify()
const stringify  = require('json-stringify-deterministic');
const sortKeysRecursive  = require('sort-keys-recursive');
const { Contract } = require('fabric-contract-api');
const Ajv = require('ajv');
const addFormats = require('ajv-formats');
//carbon json schema
const schema_createData = {
    type: "object",
    properties: {
          ProductId: {
            description: "ProductId for iso-14067",
            type: "string"
          },
          ProductAmount: {
            description: "Product amount for iso-14067",
            type: "integer",
            minimum: 0
          },
          TimeTag: {
            description: "timeTag for iso-14067",
            type: "string",
            pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}$",
            format: "date-time"
          },
          OrderId: {
            description: "orderId for iso-14067",
            type: "string"
          },
          EnergyCarbonEmission: {
            description: "EnergyCarbonEmission for iso-14067",
            type: "number",
            minimum: 0
          },
          MaterialCarbonEmission: {
            description: "MaterialCarbonEmission for iso-14067",
            type: "number",
            minimum: 0
          },
          ProductCarbonEmission: {
            description: "ProductCarbonEmission for iso-14067",
            type: "number",
            minimum: 0
          }
      },
      required: [ "ProductId","ProductAmount","TimeTag","OrderId","EnergyCarbonEmission","MaterialCarbonEmission","ProductCarbonEmission"]
};
const schema_searchData = {
    type: "object",
    properties: {
        ProductId: {
            description: "ProductId for iso-14067",
            type: "string"
          },
          StartDateTime: {
            description: "timeTag for iso-14067",
            type: "string",
            pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
            format: "date"
          },
          EndDateTime: {
            description: "timeTag for iso-14067",
            type: "string",
            pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
            format: "date"
          },
      },
      required: [ "ProductId","StartDateTime","EndDateTime"]
};
class DataTransfer extends Contract {
  //CreateData
   async CreateData(ctx, productid, productamount,timetag, orderid, energycarbonemission, materialcarbonemission, productcarbonemission) {
       const key=productid+"~"+timetag;
       const exists = await this.DataExists(ctx,key);
       if (exists) {
           throw new Error(`The data already exists`);
       }
       const data = {
           Key: key,
           ProductId: productid,
           ProductAmount: productamount,
           TimeTag: timetag,
           OrderId: orderid,
           EnergyCarbonEmission: energycarbonemission,
           MaterialCarbonEmission: materialcarbonemission,
           ProductCarbonEmission: productcarbonemission,
       };
       const create_inspection={
           ProductId: productid,
           ProductAmount: parseInt(productamount),
           TimeTag: timetag,
           OrderId: orderid,
           EnergyCarbonEmission: Number(energycarbonemission),
           MaterialCarbonEmission: Number(materialcarbonemission),
           ProductCarbonEmission: Number(productcarbonemission),
       };
       await this.CreateDataFormat(create_inspection);
       await ctx.stub.putState(key, Buffer.from(stringify(sortKeysRecursive(data))));
       return true;
   }

   // ReadData
   async ReadData(ctx, key) {
       const DataJSON = await ctx.stub.getState(key); // get the asset from chaincode state
       if (!DataJSON || DataJSON.length === 0) {
           throw new Error(`The data ${timetag} does not exist`);
       }
       return DataJSON.toString();
   }
   
   // DataExists
   async DataExists(ctx, key) {
       const assetJSON = await ctx.stub.getState(key);
       return assetJSON && assetJSON.length > 0;
   }
   //CreateDataFormat
   async CreateDataFormat(data){
      const ajv = new Ajv();
      addFormats(ajv);
      const validate = ajv.compile(schema_createData);
      const isValid = validate(data);
      if (!isValid) {
         throw new Error(validate.errors[0].instancePath+" "+validate.errors[0].message);
      }
      if(data.ProductCarbonEmission!=data.EnergyCarbonEmission+data.MaterialCarbonEmission){
        throw new Error("Value doesn't match");
      }
      
   }
   // GetAllData
   async GetAllData(ctx) {
       const allResults = [];
       const iterator = await ctx.stub.getStateByRange('', '');
       let result = await iterator.next();
       while (!result.done) {
           const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
           let record;
           try {
               record = JSON.parse(strValue);
           } catch (err) {
               console.log(err);
               record = strValue;
           }
           allResults.push(record);
           result = await iterator.next();
       }
       return JSON.stringify(allResults);
   }
   //GetAllDataAmount
   async GetAllDataAmount(ctx) {
       var allResultsAmount = 0;
       const iterator = await ctx.stub.getStateByRange('', '');
       let result = await iterator.next();
       while (!result.done) {
           allResultsAmount=allResultsAmount+1;
           result = await iterator.next();
       }
       return allResultsAmount.toString();
   }
   //(GetEquipmentCarbonDisclosureInfo)
   async GetData(ctx,productid,startDateTime, endDateTime) {
       const allResults = [];
       const search_inspection={
           ProductId: productid,
           StartDateTime: startDateTime,
           EndDateTime: endDateTime,
       };
       await this.SearchDataFormat(search_inspection);
       startDateTime = productid+"~"+startDateTime;
       endDateTime=productid+"~"+endDateTime;
       const iterator = await ctx.stub.getStateByRange(startDateTime, endDateTime+".0001");
       let result = await iterator.next();
       while (!result.done) {
           const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
           let record;
           try {
               record = JSON.parse(strValue);
           } catch (err) {
               console.log(err);
               record = strValue;
           }
           allResults.push(record);
           result = await iterator.next();
       }
       return JSON.stringify(allResults);
   }
   //GetDataAmount
   async GetDataAmount(ctx,productid,startDateTime, endDateTime) {
       const allResults = [];
       const search_inspection={
           ProductId: productid,
           StartDateTime: startDateTime,
           EndDateTime: endDateTime,
       };
       await this.SearchDataFormat(search_inspection);
       const split_ref_start_date= startDateTime.split('-');
       const split_ref_end_date= endDateTime.split('-');
       const pick_ref_start_date = new Date(split_ref_start_date[1]+"/"+split_ref_start_date[2]+"/"+split_ref_start_date[0]);
       const pick_ref_end_date = new Date(split_ref_end_date[1]+"/"+split_ref_end_date[2]+"/"+split_ref_end_date[0]);
       const from_start_to_end_days = (Math.abs (pick_ref_end_date.getTime()-pick_ref_start_date.getTime()))/(1000 * 3600 * 24);
       const productid_startDateTime = productid+"~"+startDateTime;
       const productid_endDateTime=productid+"~"+endDateTime;
       const iterator = await ctx.stub.getStateByRange(productid_startDateTime, productid_endDateTime+".0001");
       for (var i =0;i<=from_start_to_end_days;i++){
         allResults.push(0);
       }
       let result = await iterator.next();
       while (!result.done) {
           const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
           let record;
           try {
               record = JSON.parse(strValue);
               const new_date = record.TimeTag.split(' ');
               const split_new_date = new_date[0].split('-');
               const pick_new_date=new Date(split_new_date[1]+"/"+split_new_date[2]+"/"+split_new_date[0]);
               const from_start_to_new_days = (Math.abs (pick_new_date.getTime()-pick_ref_start_date.getTime()))/(1000 * 3600 * 24);
               allResults[from_start_to_new_days]=allResults[from_start_to_new_days]+1;
           } catch (err) {
               console.log(err);
               record = strValue;
           }
           result = await iterator.next();
       }
       return allResults;
   }
   //SearchDataFormat
   async SearchDataFormat(data){
      const ajv = new Ajv();
      addFormats(ajv);
      const validate = ajv.compile(schema_searchData);
      const isValid = validate(data);
      if (!isValid) {
         throw new Error(validate.errors[0].instancePath+" "+validate.errors[0].message);
      }
   }
}

module.exports = DataTransfer;