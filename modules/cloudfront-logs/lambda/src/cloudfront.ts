import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3"
import zlib from "zlib"
import qs from "querystring"
import { promisify } from "util"

const unzip = promisify(zlib.gunzip);

type ParseVersionFunction = (line?: string) => string;

export const parseVersion: ParseVersionFunction = (line) => {
    if (!line || !line.startsWith("#Version:")) {
        throw new Error(`Invalid version line '${line}'`);
    }

    const match = line.match(/[\d.]+$/);
    if (!match) {
        throw new Error(`Could not parse version from line '${line}'`);
    }

    return match.toString();
}

type ParseFieldsFunction = (line?: string) => string[];

export const parseFields: ParseFieldsFunction = (line) => {
    if (!line || !line.startsWith("#Fields:")) {
        throw new Error(`Invalid fields line '${line}'`);
    }

    const match = line.match(/[\w()-]+(\s|$)/g)
    if (!match) {
        return [];
    }

    return match.map(field => (
        // Strip parentheses and remove abbreviations in field names
        field.replace(/\(([^)]+)\)/, '-$1').replace(/^(c-|cs-|sc-)/, '').trim().toLowerCase()
    ))
}

export const decode = (value: string): string => qs.unescape(qs.unescape(value));

type ParseLineFunction = (line: string, fields: string[]) => Record<string, string>;

export const parseLine: ParseLineFunction = (line, fields) => {
    if (line.startsWith("#")) {
        throw new Error(`Invalid log line '${line}'`)
    }

    return line.split("\t").reduce<Record<string, string>>((object, section, index) => {
        if (section === "-") {
            return object;
        }

        return {
            ...object,
            [fields[index]]: decode(section)
        }
    }, {})
}


type GetLogFileOptions = {
    bucket: string;
    key: string;
    region: string;
}

type GetLogFileFunction = (options: GetLogFileOptions) => Promise<string>;

export const getLogFile: GetLogFileFunction = async (options) => {
    const client = new S3Client({ region: options.region });
    const command = new GetObjectCommand({
        Bucket: options.bucket,
        Key: options.key
    })

    const response = await client.send(command);
    if (!response.Body) {
        throw new Error(`Log file zip has no body - bucket=${options.bucket} key=${options.key}`)
    }

    const buffer = await unzip(await response.Body.transformToByteArray())

    return buffer.toString().trim();
}

type ParseLogFileOptions = {
    bucket: string;
    key: string;
    region: string;
};

type ParseLogFileFunction = (options: ParseLogFileOptions) => Promise<Record<string, string>[]>;

export const parseLogFile: ParseLogFileFunction = async (options) => {
    const file = await getLogFile(options);

    const lines = file.split("\n")

    parseVersion(lines.shift());
    const fields = parseFields(lines.shift());

    return lines.map(line => parseLine(line, fields));
}