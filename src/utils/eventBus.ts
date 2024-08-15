const events: Map<string, CallableFunction[]> = new Map();

export default {
    $emit: function (key: string, ...args: any[]) {
        for (const handler of events.get(key)||[]) {
            handler(...args);
        }
    },
    $on: function (key: string, handler: CallableFunction) {
        if (!events.has(key)) {
            events.set(key, []);
        }

        events.get(key)?.push(handler);
    },
    $off: function (key: string, handler?: CallableFunction) {
        if (handler) {
            let handlers = events.get(key);
            if (!handlers) return;
            events.set(key, handlers.filter((h) => h != handler));
        } else {
            events.set(key, []);
        }
    }

};
