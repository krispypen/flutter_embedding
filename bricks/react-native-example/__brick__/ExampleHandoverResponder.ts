import {
    HandoverResponderInterface
} from 'flutter-rn-embedding';

export class ExampleHandoverResponder implements HandoverResponderInterface {
    exitCallback: () => void;

    constructor({
        exit,
    }: {
        exit: () => void;
    }) {
        this.exitCallback = exit;
    }

    exit(): void {
        this.exitCallback();
    }

    invokeHandover(name: string, data: any, completion: (response: any, error: any) => void): void {
        console.log(`Invoke handover: ${name} with data: ${JSON.stringify(data)}`);
        completion(null, null);
    }
} 