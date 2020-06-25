# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rest-client'

gitlab_url = attribute('gitlab_url')

control "gcloud" do
	title "gitlab url"
	describe "gitlab" do
		it "is reachable" do
			expect {
				10.times do
					unless host(gitlab_url.delete_prefix("https://"), port: 443, protocol: 'tcp').reachable?
						puts "Gitlab is not reachable, retrying.."
						sleep 10
					end
				end
				RestClient.get(gitlab_url)
			}.to_not raise_exception
		end
	end
end
