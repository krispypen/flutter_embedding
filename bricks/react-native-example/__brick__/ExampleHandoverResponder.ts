import {
    HandoverResponderInterface
} from '{{reactNativePackageName}}';

export class ExampleHandoverResponder implements HandoverResponderInterface {
    exitCallback: () => void;
    invokeHandoverCallback: (name: string, data: any, completion: (response: any, error: any) => void) => void;

    constructor({
        exit,
        invokeHandover,
    }: {
        exit: () => void;
        invokeHandover: (name: string, data: any, completion: (response: any, error: any) => void) => void;
    }) {
        this.exitCallback = exit;
        this.invokeHandoverCallback = invokeHandover;
    }

    exit(): void {
        console.log("exit in exampleHandoverResponder.ts");
        this.exitCallback();
    }

    invokeHandover(name: string, data: any, completion: (response: any, error: any) => void): void {
        console.log(`Invoke handover: ${name} with data: ${JSON.stringify(data)}`);
        this.invokeHandoverCallback(name, data, completion);
    }
} 