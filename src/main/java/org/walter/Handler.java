package org.walter;

/**
 * Hello world!
 *
 */

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
public class Handler implements RequestHandler<Request, Response> {

    @Override
    public Response handleRequest(Request request, Context context) {

        context.getLogger().log("Received request");

        String message = "Hello " + request.getName();
        System.out.println(message);

        return new Response(message);
    }
}
