export default function () {
  this.route("ballotage", { path: "/ballotage" }, function () {
    this.route("manage");
  });
}
