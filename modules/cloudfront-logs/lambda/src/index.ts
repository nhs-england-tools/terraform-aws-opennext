import { parseLogFile } from "./cloudfront";
import { putLogEvents } from "./cloudwatch-logs";
import {type Handler, S3Event} from "aws-lambda"
import util from "util";

export const handler: Handler<S3Event> = async (event, context) => {
    if (event.Records.length !== 1) {
        throw new Error(`Wrong length of event.Records, expected '1', got '${event.Records.length}'`);
    }

    const records = await parseLogFile({
        bucket: event.Records[0].s3.bucket.name,
        key: decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' ')),
        region: event.Records[0].awsRegion
    });

    const result = await putLogEvents(records);
    
    const isSuccessful = result.every(output => output.$metadata.httpStatusCode === 200);
    if (!isSuccessful) {
        throw new Error(`One or more PutLogCommands failed:\n${util.inspect(result)}`);
    }
}